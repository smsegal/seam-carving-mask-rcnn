using SeamCarving, Test, FileIO

@testset "Some tests" begin
    img = load("../ryerson.jpg")
    @test size(SeamCarving.resize(img, (200, 200))) == (200,200)
end
