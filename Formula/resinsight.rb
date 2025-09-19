class Resinsight < Formula
  desc "3D viewer and post processing of reservoir models"
  homepage "https://resinsight.org"

  url "https://github.com/OPM/ResInsight.git",
    using:    :git,
    tag:      "v2025.09.1",
    revision: "a3ec18bd045c39a1b1da3412b3a34a30667dadbb"

  license all_of: [
    "GPL-3.0-or-later"
  ]

  depends_on "cmake" => :build
  depends_on "ninja" => :build
  depends_on "type-lite" => :build
  depends_on "python" => :build
  depends_on "pugixml" => :build
  depends_on "eigen" => :build
  depends_on "fast_float" => :build
  depends_on "boost@1.85"
  depends_on "libomp"
  depends_on "qt"
  depends_on "spdlog"
  depends_on "apache-arrow"
  depends_on "fmt"

  def self.cmake_args
    libomp = Formula["libomp"]
    fmt = Formula["fmt"]
    boost = Formula["boost@1.85"]
    [
      "-G", "Ninja",
      "-DHOMEBREW_ALLOW_FETCHCONTENT=ON",
      "-DRESINSIGHT_INCLUDE_APPLICATION_UNIT_TESTS=OFF",
      "-DRESINSIGHT_TREAT_WARNINGS_AS_ERRORS=OFF",
      "-DRESINSIGHT_ENABLE_UNITY_BUILD=OFF",
      "-DRESINSIGHT_ENABLE_GRPC=OFF",
      "-DRESINSIGHT_ENABLE_OPENVDS=OFF",
      # TODO: opm-common incorrectly links the fmt target, so currently one needs `brew link fmt`
      "-Dfmt_ROOT='#{fmt.prefix}'",
      "-DBoost_ROOT='#{boost.prefix}'",
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5",
      # Apple Clang + Homebrew needs special arguments for OpenMP
      "-DRESINSIGHT_USE_OPENMP=OFF",
      "-DCMAKE_DISABLE_FIND_PACKAGE_OpenMP=ON",
      "-DCMAKE_CXX_FLAGS='-Xpreprocessor -fopenmp -I#{libomp.opt_include} -DUSE_OPENMP'",
      "-DCMAKE_EXE_LINKER_FLAGS='-L#{libomp.lib} -lomp'",
      "-DCMAKE_SHARED_LINKER_FLAGS='-L#{libomp.lib} -lomp'"
    ]
  end

  patch_dir = "file://#{Pathname.new(__FILE__).dirname}/patches/resinsight/v2025.09.1"
  patch :p1 do
      url "#{patch_dir}/cpp20-stacktrace.patch"
      sha256 "7ca084555c77883714bf0dfca0769684681d9824da72f5a0afad15626dd76881"
  end
  patch :p1 do
      url "#{patch_dir}/cpp20-spanstream.patch"
      sha256 "b8cfd36076083b634c0db9383eb124f8ecad25702186b481b8fb1322df704e32"
  end
  patch :p1 do
      url "#{patch_dir}/clang-16.patch"
      sha256 "5884e6cf4f44b95a4879df70bc2caf3f5186e70cdaf478d912e6b5603179e349"
  end
  patch :p1 do
      url "#{patch_dir}/open-file.patch"
      sha256 "a2754aeeeb1535fdef27ebfe405a755c36c78a1a51b41398b05191079c87c1f8"
  end

  head do
    url "https://github.com/OPM/ResInsight.git",
      branch: "dev",
      using: :git

    patch_dir = "file://#{Pathname.new(__FILE__).dirname}/patches/resinsight/head"
    patch :p1 do
        url "#{patch_dir}/cpp20-stacktrace.patch"
        sha256 "7ca084555c77883714bf0dfca0769684681d9824da72f5a0afad15626dd76881"
    end
    patch :p1 do
        url "#{patch_dir}/cpp20-spanstream.patch"
        sha256 "b8cfd36076083b634c0db9383eb124f8ecad25702186b481b8fb1322df704e32"
    end
    patch :p1 do
        url "#{patch_dir}/clang-16.patch"
        sha256 "5884e6cf4f44b95a4879df70bc2caf3f5186e70cdaf478d912e6b5603179e349"
    end
    patch :p1 do
        url "#{patch_dir}/open-file.patch"
        sha256 "a2754aeeeb1535fdef27ebfe405a755c36c78a1a51b41398b05191079c87c1f8"
    end
  end

  def install
    source_dir = buildpath/"src"
    build_dir = buildpath/"build"
    formula_dir = Pathname.new(__FILE__).dirname

    # move source to its own directory, otherwise, cmake complains of in-source builds
    items = Dir[".[!.]*"] + Dir["*"]
    mkdir source_dir
    FileUtils.mv(items, source_dir)

    system "git", "-C", source_dir, "submodule", "update", "--init", "--recursive"
    system "git", "-C", source_dir, "apply", "#{formula_dir}/patches/resinsight/head/surfio-from-chars.patch"
    system "git", "-C", source_dir/"ThirdParty/openzgy/open-zgy", "apply", "#{formula_dir}/patches/resinsight/head/open-zgy.patch"

    system "cmake", "-S", source_dir, "-B", build_dir, *std_cmake_args, *Resinsight.cmake_args
    system "cmake", "--build", build_dir
    system "cmake", "--install", build_dir

    # Use macdeployqt to bundle Qt frameworks (the one in CMake seems not to work properly)
    app = prefix/"ResInsight.app"
    system Formula["qt"].opt_bin/"macdeployqt", app,
       "-always-overwrite",
       "-executable=#{app}/Contents/MacOS/ResInsight"

    # Create a relative symlink inside the frameworks dir (fixes runtime issues)
    Dir.chdir(app/"Contents/Frameworks") do
      File.symlink("libresdata.dylib", "libresdata.2.dylib") unless File.exist?("libresdata.2.dylib")
    end

    bin.install_symlink prefix/"ResInsight.app/Contents/MacOS/ResInsight"
  end

  # test do
  #   system "false"
  # end
end
