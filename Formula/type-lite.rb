class TypeLite < Formula
  desc " Strong types for C++98, C++11 and later in a single-file header-only library"

  url "https://github.com/martinmoene/type-lite.git",
    using:    :git,
    tag:      "v0.2.0",
    revision: "edce3fb26f53ef9b2f8a35b8825d10c5f5e8443f"

  license "BSD-1-Clause"

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  def self.cmake_args
    [
      "-G", "Ninja Multi-Config",
      "-DCMAKE_BUILD_TYPE=Release"
    ]
  end

  def install
    system "cmake", ".", *std_cmake_args, *TypeLite.cmake_args
    system "cmake", "--build", ".", "--target", "install"
  end

  # test do
  #   system "false"
  # end
end
