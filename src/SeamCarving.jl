using Images, ImageView, LinearAlgebra, FileIO, Statistics

function resize(img, newSize::NTuple{2,Int})
    carved = img
    for diff in reverse(size(img) .- newSize)
        diffMag = abs(diff)
        if diff > 0 #shrink along dim
            println("shrink")
            carved, _ = shrinkDim(carved, diffMag)
        elseif diff < 0 #grow along dim
            println("grow")
            carved = growDim(carved, diffMag)
        end
        carved = carved'
    end
    return carved
end

function growDim(img, diff)
    _, seams = shrinkDim(img, diff)
    currentImage = img
    for i ∈ 1:diff
        grownImage = zeros(eltype(currentImage), size(currentImage) .+ (0,1))
        println(string("Growth Iteration ", i, "/", diff))
        for (row, s) ∈ enumerate(seams[i])
            grownImage[row,:] = [currentImage[row,1:s]; currentImage[row,s]; currentImage[row,s+1:end]]
        end
        currentImage = grownImage
    end
    return currentImage
end

function shrinkDim(img, diff)
    currentImage = img
    seams = fill(Vector{Int}(undef, size(img,1)), diff)
    seamFromImage = generateSeam ∘ score ∘ padsides ∘ energy
    for i ∈ 1:diff
        println(string("Iteration ", i, "/", diff))
        seams[i] = seamFromImage(currentImage)
        shrunkImage = zeros(eltype(currentImage), size(currentImage) .- (0,1))
        for (row, s) ∈ enumerate(seams[i])
            shrunkImage[row,:] = [currentImage[row,1:s-1]; currentImage[row,s+1:end]]
        end
        currentImage = shrunkImage
    end
    return currentImage, seams
end

removeSeamPoint(row, s) = @views [row[1:s-1]; row[s+1:end]]
addSeamPoint(row, s) = @views [row[1:s]; mean(row[s .+ [-1:1;]]); row[s+1:end]]

getThird((_,_,third)) = third
energy(img) = (getThird ∘ imedge)(img, Kernel.ando3)

function score(energy)
    M = fill(Inf, size(energy)) #M is our scoring matrix
    M[1,:] = energy[1,:] #Scoring matrix is seeded with the first row of the energy matrix
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

        #shift by two so that the min array is a [-1,0,1] offset from the seam coord below it
        seam[i] += seam[i + 1] - 2
    end
    return seam .- 1 #account for the padding
end

function padsides(array, val=Inf)
    padVect = fill(val, size(array,1))
    return [padVect array padVect]
end
