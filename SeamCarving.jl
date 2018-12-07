using Images, ImageView, LinearAlgebra;

module SeamCarving

function resize(img, newSize::NTuple{2,Int})
    carved = img;
    for diff in size(img) .- newSize
        if diff > 0 #shrink along dim
            carved = shrinkDim(carved, diff)
        elseif diff < 0 #grow along dim
            carved = growDim(carved, diff)
        end
        carved = carved';
    end
    return carved;
end

function shrinkDim(img, diff)
    println(string("shrink: ",size(img)));
    return img
end

function growDim(img, diff)
    println(string("grow: ",size(img)));
    return img
end

end
