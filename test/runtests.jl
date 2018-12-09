using Test, FileIO
include("./../src/SeamCarving.jl")


img = load("./../ryerson.jpg")
function sce2e()
    small = resize(img, (400,700))
    large = resize(img, (500,800))
    return small, large
end

@testset "End2End Resizing" begin
    small, large = sce2e()
    @test size(small) == (400,700)
    @test size(large) == (500,800)
end
