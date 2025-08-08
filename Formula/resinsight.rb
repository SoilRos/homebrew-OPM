class Resinsight < Formula
  desc "3D viewer and post processing of reservoir models"
  homepage "https://resinsight.org"

  url "https://github.com/OPM/ResInsight.git",
    using:    :git,
    tag:      "v2025.04.3.1",
    revision: "c33402f5ea4bde4b02cbe50a5567816f605335e9"

  head "https://github.com/OPM/ResInsight.git", branch: "dev", using: :git

  license all_of: [
    "GPL-3.0-or-later"
  ]

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "type-lite" => :build
  depends_on "python" => :build
  depends_on "pugixml" => :build
  depends_on "boost"
  depends_on "libomp"
  depends_on "qt"
  depends_on "spdlog"
  depends_on "apache-arrow"
  depends_on "fmt"

  head do
     formula_dir = Pathname.new(__FILE__).dirname
     patch :p1 do
          url "file://#{formula_dir}/patches/resinsight-remove-open-vds.patch"
          sha256 "45f97b82fbc7d778a8c8f771f5a2e7fbc9dd9923318029795f6280248b4ef706"
     end
     patch :p1 do
          url "file://#{formula_dir}/patches/resinsight-cpp20-stacktrace.patch"
          sha256 "7ca084555c77883714bf0dfca0769684681d9824da72f5a0afad15626dd76881"
     end
     patch :p1 do
          url "file://#{formula_dir}/patches/resinsight-cpp20-spanstream.patch"
          sha256 "b8cfd36076083b634c0db9383eb124f8ecad25702186b481b8fb1322df704e32"
     end
     patch :p1 do
          url "file://#{formula_dir}/patches/resinsight-clang-17.patch"
          sha256 "22c42412197386a1181fb587c2c68090bd92a49c37e0efd0dc8cd451bb08b077"
     end
     patch :p1 do
          url "file://#{formula_dir}/patches/resinsight-templated-function.patch"
          sha256 "fc638d712bac443f3818d73a002e897090812040ff6ea518dda92673451d6a69"
     end
     patch :p1 do
          url "file://#{formula_dir}/patches/resinsight-install-bundle.patch"
          sha256 "080cbfc6621808b6abe2e8b893435d4b46a8072404a7898c33c6b03d4a13700a"
     end
     patch :p1 do
          url "file://#{formula_dir}/patches/resinsight-open-file.patch"
          sha256 "a2754aeeeb1535fdef27ebfe405a755c36c78a1a51b41398b05191079c87c1f8"
     end
  end

  def self.cmake_args
    libomp = Formula["libomp"]
    [
      "-G", "Ninja",
      "-DHOMEBREW_ALLOW_FETCHCONTENT=ON",
      "-DRESINSIGHT_INCLUDE_APPLICATION_UNIT_TESTS=OFF",
      "-DRESINSIGHT_TREAT_WARNINGS_AS_ERRORS=OFF",
      "-DRESINSIGHT_ENABLE_UNITY_BUILD=OFF",
      "-DRESINSIGHT_ENABLE_GRPC=OFF",
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
      # Apple Clang + Homebrew needs special arguments for OpenMP
      "-DRESINSIGHT_USE_OPENMP=OFF",
      "-DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=ON",
      "-DCMAKE_CXX_FLAGS='-Xpreprocessor -fopenmp -I#{libomp.opt_include} -DUSE_OPENMP'",
      "-DCMAKE_EXE_LINKER_FLAGS='-L#{libomp.opt_lib} -lomp'",
      "-DCMAKE_SHARED_LINKER_FLAGS='-L#{libomp.opt_lib} -lomp'"
    ]
  end

  resource "surfio" do
     url "https://github.com/equinor/surfio.git" ,
          using:    :git,
          branch: "main",
          revision: "9ba7fca3e8796708b5d01f76b6c8d4ff8167c0bcf90f67c4aa4a5f9397de3c46"
  end

  def install
     source_dir = buildpath/"src"
     build_dir = buildpath/"build"
     formula_dir = Pathname.new(__FILE__).dirname

     # move source to its own directory, otherwise, cmake complains of in-source builds
     items = Dir[".[!.]*"] + Dir["*"]
     mkdir source_dir
     FileUtils.mv(items, source_dir)

     # override surfio with latest version
     resource("surfio").stage "surfio"
     surfio_dir = source_dir/"ThirdParty/custom-surfio/surfio"
     FileUtils.rm_rf(surfio_dir) if surfio_dir.exist?
     FileUtils.mv("surfio", surfio_dir)

     system "git", "-C", source_dir, "submodule", "update", "--init", "--recursive"
     system "git", "-C", source_dir, "apply", "#{formula_dir}/patches/resinsight-surfio-from-chars.patch"
     system "git", "-C", source_dir/"ThirdParty/openzgy/open-zgy", "apply", "#{formula_dir}/patches/resinsight-open-zgy.patch"

     system "cmake", "-S", source_dir, "-B", build_dir, *std_cmake_args, *Resinsight.cmake_args
     system "cmake", "--build", build_dir
     system "cmake", "--install", build_dir, "--component", "Runtime"
     bin.install_symlink prefix/"ResInsight.app/Contents/MacOS/ResInsight"
  end

  # test do
  #   system "false"
  # end
end
