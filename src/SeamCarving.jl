using Images, ImageView, LinearAlgebra, FileIO

function resize(img, newSize::NTuple{2,Int})
    carved = img
    for diff in reverse(size(img) .- newSize)
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
    currentImage = img
    for i ∈ 1:diff
        println(string("Iteration ", i, "/", diff))
        seam = (generateSeam ∘ score ∘ padsides ∘ energy)(currentImage)
        currentImage = changeImage(currentImage, seam)
    end
    return currentImage
end

removeSeam(img, seam) = handleSeam(removeSeamPoint, img, seam)
addSeam(img, seam) = handleSeam(addSeamPoint, img, seam)

function handleSeam(adjustRow, img, seam)
    (transpose ∘ mapreduce)(hcat, enumerate(seam)) do (i, s)
        @views adjustRow(img[i,:], s)
    end
end

removeSeamPoint(row, s) = @views [row[1:s-1]; row[s+1:end]]
addSeamPoint(row, s) = @views [row[1:s]; row[s]; row[s+1:end]]

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
    # println("score matrix: ", summary(M))
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
    seam = seam .- 1 #account for the padding
    return Int.(seam)
end

padsides(array::AbstractArray) = padsides(array, Inf)
function padsides(array::AbstractArray, val)
    padVect = fill(Inf, size(array,1))
    return [padVect array padVect]
end
