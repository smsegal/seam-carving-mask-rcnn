using Images, ImageView, LinearAlgebra;

module SeamCarving

function resize(img, newSize::NTuple{2,Int})
    carved = img
    for diff in size(img) .- newSize
        diffMag = abs(diff)
        if diff > 0 #shrink along dim
            carved = shrinkDim(carved, diffMag)
        elseif diff < 0 #grow along dim
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
