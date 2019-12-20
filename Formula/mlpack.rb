class Mlpack < Formula
  desc "Scalable C++ machine learning library"
  homepage "https://www.mlpack.org"
  url "https://mlpack.org/files/mlpack-3.2.2.tar.gz"
  sha256 "7aef8c27645c9358262fec9ebba380720a086789d6519d5d1034346412a52ad6"

  depends_on "cmake" => :build
  depends_on "doxygen" => :build
  depends_on "pkg-config" => :build
  depends_on "armadillo"
  depends_on "boost"
  depends_on "ensmallen"
  depends_on "graphviz"

  def install
    cmake_args = std_cmake_args
    cmake_args << "-DDEBUG=OFF"
    cmake_args << "-DPROFILE=OFF"
    cmake_args << "-DDOWNLOAD_STB_IMAGE=OFF"
    cmake_args << "-DARMADILLO_INCLUDE_DIR=#{Formula["armadillo"].opt_include}"
    cmake_args << "-DENSMALLEN_INCLUDE_DIR=#{Formula["ensmallen"].opt_include}"
    cmake_args << "-DARMADILLO_LIBRARY=#{Formula["armadillo"].opt_lib}/libarmadillo.dylib"
    cmake_args << "-DCMAKE_CXX_FLAGS=-fext-numeric-literals" unless ENV.compiler == :clang

    mkdir "build" do
      system "cmake", "..", *cmake_args
      system "make", "install"
    end

    doc.install Dir["doc/*"]
    pkgshare.install "src/mlpack/tests" # Includes test data.
  end

  test do
    cd testpath do
      system "#{bin}/mlpack_knn",
        "-r", "#{pkgshare}/tests/data/GroupLensSmall.csv",
        "-n", "neighbors.csv",
        "-d", "distances.csv",
        "-k", "5", "-v"
    end

    (testpath / "test.cpp").write <<-EOS
      #include <mlpack/core.hpp>

      using namespace mlpack;

      int main(int argc, char** argv) {
        Log::Debug << "Compiled with debugging symbols." << std::endl;
        Log::Info << "Some test informational output." << std::endl;
        Log::Warn << "A false alarm!" << std::endl;
      }
    EOS
    cxx_with_flags = ENV.cxx.split + ["test.cpp",
                                      "-std=c++11",
                                      "-I#{include}",
                                      "-I#{Formula["armadillo"].opt_lib}/libarmadillo",
                                      "-L#{lib}", "-lmlpack",
                                      "-o", "test"]
    system *cxx_with_flags
    system "./test", "--verbose"
  end
end
