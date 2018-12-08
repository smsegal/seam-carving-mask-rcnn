using SeamCarving, Test

function tests()
    img = imread("../ryerson.jpg")
    @testset "Some tests" begin
        @test size(resize(img, (200, 200))) == (200,200)
