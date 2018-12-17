using Images, LinearAlgebra, FileIO, Statistics, PyCall
ENV["PYTHON"] = "python"
pushfirst!(PyVector(pyimport("sys")["path"]), "")
@pyimport imageMasks
@pyimport numpy as np

function resize(img, newSize::NTuple{2,Int}; fancy=true)
    carved = img
    if fancy
        shrinkDimLocal = (im, dm) -> shrinkDim(im, dm, energy)
    else
        shrinkDimLocal = (im, dm) -> shrinkDim(im, dm, plainEnergy)
    end
    growDimLocal = (im, dm) -> growDim(im, dm, fancy)

    for diff in reverse(size(img) .- newSize)
        diffMag = abs(diff)
        if diff > 0 #shrink along dim
            println("shrink")
            carved, _ = shrinkDimLocal(carved, diffMag)
        elseif diff < 0 #grow along dim
            println("grow")
            carved = growDimLocal(carved, diffMag)
        end
        carved = carved'
    end
    return carved
end

function contentAmplification(img, factor)
    larger = imresize(img, ratio=factor)
    return resize(larger, size(img))
end

function growDim(img, diff, fancy)
    if fancy
        shrinkDimLocal = (im, dm) -> shrinkDim(im, dm, energy)
    else
        shrinkDimLocal = (im, dm) -> shrinkDim(im, dm, plainEnergy)
    end

    _, seams = shrinkDimLocal(img, diff)
    currentImage = img
    for i ∈ 1:diff
        println(string("Growth Iteration ", i, "/", diff))
        grownImage = zeros(eltype(currentImage), size(currentImage) .+ (0,1))
        addSeam!(grownImage, currentImage, seams[i])
        currentImage = grownImage
    end
    return currentImage
end

function seamFromImage(img, energyFunc)
    (generateSeam ∘ score ∘ padsides ∘ energyFunc)(img)
end

function shrinkDim(img, diff, energyType)
    currentImage = img
    seams = fill(Vector{Int}(undef, size(img,1)), diff)
    for i ∈ 1:diff
        println(string("Iteration ", i, "/", diff))
        seams[i] = seamFromImage(currentImage,energyType)
        shrunkImage = zeros(eltype(currentImage), size(currentImage) .- (0,1))
        removeSeam!(shrunkImage, currentImage, seams[i])
        currentImage = shrunkImage
    end
    return currentImage, seams
end

function removeSeam!(shrunkImage, prevImage, seam)
    for (row, s) ∈ enumerate(seam)
        shrunkImage[row,:] .= [prevImage[row,1:s-1]; prevImage[row,s+1:end]]
    end
end

function addSeam!(grownImage, prevImage, seam)
    for (row, s) ∈ enumerate(seam)
        grownImage[row,:] .= [prevImage[row,1:s]; prevImage[row,s]; prevImage[row,s+1:end]]
    end
end

getThird((_,_,third)) = third
function plainEnergy(img)
    (getThird ∘ imedge)(img, Kernel.ando3)
end
function energy(img)
    magnitude = (getThird ∘ imedge)(img, Kernel.ando3)
    #=
    masked regions are to be element-wise multiplied by the magnitude image,
    so they should be 1 .+ a one-hot encoded
    =#
    maskedregions = masks(img)
    return maskedregions .* magnitude
end

maskgen = imageMasks.MaskGenerator()
# function stub
function masks(img)
    pyimg = channelview(img)
    pyimg = permutedims(pyimg,[2,3,1])
    pyimg = round.(Int, 255 .* np.array(pyimg))
    immasks = maskgen[:computeMasks](pyimg)
    intmasks = mapslices(immasks, dims=[3]) do mask
        map(mp -> mp ? 1 : 0, mask)
    end
    allmasks = zeros(size(intmasks[:,:,1]))
    for i ∈ 1:size(intmasks,3)
        allmasks .+= intmasks[:,:,i]
    end
    return (allmasks .* 20) .+ 1
end

function score(energy)
    M = fill(Inf, size(energy)) #M is our scoring matrix
    M[1,:] .= energy[1,:] #Scoring matrix is seeded with the first row of the energy matrix
    xrange = -1:1
    height, width = size(M)
    for y = 2:height, x = 2:(width - 1)
        M[y,x] = energy[y,x] + minimum(M[y-1, x .+ xrange])
    end
    return M
end

function generateSeam(score)
    height, _ = size(score)
    seam = zeros(height)
    offsets = -1:1
    _, seam[end] = findmin(score[end,:])
    for i = (height - 1):-1:1
        row = score[i,:]
        _, seam[i] = findmin(row[Int.(seam[i + 1] .+ offsets)])

        #shift by 2 + 1 so that the min array is a [-1,0,1] offset from the seam coord below it and padding is accounted for
        seam[i] += seam[i + 1] - 2
    end
    return seam .- 1 #account for the padding
end

function padsides(array, val=Inf)
    padVect = fill(val, size(array,1))
    return [padVect array padVect]
end
