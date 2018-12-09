
using Images, ImageView, LinearAlgebra;

function resize(img, newSize::NTuple{2,Int})
    carved = img
    for diff in size(img) .- newSize
        diffMag = abs(diff)
        if diff > 0 #shrink along dim
            println("shrink")
            carved = shrinkDim(carved, diffMag)
        elseif diff < 0 #grow along dim
            println("grow")
            carved = growDim(carved, diffMag)
        end
        carved = carved'
    end
    return carved
end

shrinkDim(img,diff) = seamCarve(removeSeam, img, diff)
growDim(img,diff) = seamCarve(addSeam, img, diff)

function seamCarve(changeImage, img, diff)
    height, width = size(img)

    resized = reduce(img) do currentImage, next
        seam = (generateSeam ∘ score ∘ energy)(currentImage)
        return changeImage(image,seam)
    end
end

function removeSeam(img, seam)
    left = map(s -> img[:,s], seam)
    right = map(s -> img[:, s+1:end], seam)
    return [left right]
end

function addSeam(img, seam)
    left = [map(s -> img[:,s]) img[:,seam]]
    right = map(s -> img[:, s:end], seam)
    return [left right]
end

energy(img) = hypot.(imgradients(img, Kernel.ando3)...)

function score(energy)
    M = zero(energy) #M is our scoring matrix
    M[1,:] = energy[1,:] #Scoring matrix is seeded with the first row of the energy matrix
    xrange = collect(-1:1)
    Mpadded = padsides(M, Inf)
    ePadded = padsides(energy, Inf)
    pheight, pwidth = size(Mpadded)
    for y = 2:pheight
        for x = 2:(pwidth - 1)
            Mpadded[y,x] = ePadded[y,x] + minimum(Mpadded[y-1, x .+ xrange])
        end
    end
    return Mpadded
end

function generateSeam(score)
    height, _ = size(score)
    seam = zeros(height)
    offsets = collect(-1:1)
    _, seam[end] = findmin(score[end,:])
    displacement = seam[end]
    for i = (height - 1):-1:1
        row = score[i,:]
        _, seam[i] = findmin(row[Int.(seam[i + 1] .+ offsets)])
        # displacement += seam[i] - 2
        seam[i] += seam[i + 1] - 2
    end
    seam = seam .- 1 #account for the padding
    println(string("final seam: ", seam))
end

function padsides(array, val)
    padVect = fill(Inf, size(array,1))
    return [padVect array padVect]
end
