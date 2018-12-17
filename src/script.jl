using Pkg
Pkg.activate("../")
Pkg.add("PyCall")
ENV["PYTHON"] = "python"
Pkg.build("PyCall")

using PyCall
include("./SeamCarving.jl")

img = load("../assets/people-laughing.jpg")
imsmallFancy = resize(img, round.(Int, 0.9 .* size(img)), fancy=true)
imsmallPlain = resize(img, round.(Int, 0.9 .* size(img)), fancy=false)
save("./../assets/90plaughing16.png", imsmallFancy)
