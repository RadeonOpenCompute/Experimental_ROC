# rpmrebuild autogenerated specfile

%define defaultbuildroot /
AutoProv: no
%undefine __find_provides
AutoReq: no
%undefine __find_requires
# Do not try autogenerate prereq/conflicts/obsoletes and check files
%undefine __check_files
%undefine __find_prereq
%undefine __find_conflicts
%undefine __find_obsoletes
# Be sure buildpolicy set to do nothing
%define __spec_install_post %{nil}
# Something that need for rpm-4.1
%define _missing_doc_files_terminate_build 0
#ARCH:         x86_64
BuildArch:     x86_64
Name:          rocm-opencl
Version:       1.2.0
Release:       ROCM_OPENCL_PKG_VER
License:       unknown 
Group:         unknown
Summary:       OpenCL/ROCm

Source: %{expand:%%(pwd)}
BuildRoot: %{expand:%%(pwd)}


Vendor:        AMD






Prefix:        ROCM_OUTPUT_DIR/opencl
Provides:      rocm-opencl  
Provides:      libOpenCL.so.1  
Provides:      rocm-opencl = 1.2.0-ROCM_OPENCL_PKG_VER
Provides:      rocm-opencl(x86-64) = 1.2.0-ROCM_OPENCL_PKG_VER
Requires:      hsa-rocr-dev >= 1.1.5
Requires:      ocl-icd
Requires:      /bin/sh  
Requires:      /bin/sh  
Requires:      /bin/sh  
#Requires:      rpmlib(FileDigests) <= 4.6.0-1
#Requires:      rpmlib(PayloadFilesHavePrefix) <= 4.0-1
#Requires:      rpmlib(CompressedFileNames) <= 3.0.4-1
#Requires:      rpmlib(PayloadIsXz) <= 5.2-1
#suggest
#enhance
%description
DESCRIPTION
===========

%prep
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT
cd $RPM_BUILD_ROOT
cp -R %{SOURCEURL0}/* .

%clean
rm -r -f "$RPM_BUILD_ROOT"

%files
%attr(0755, root, root) "ROCM_OUTPUT_DIR/opencl/bin/x86_64/clang"
%attr(0755, root, root) "ROCM_OUTPUT_DIR/opencl/bin/x86_64/clinfo"
%attr(0755, root, root) "ROCM_OUTPUT_DIR/opencl/bin/x86_64/ld.lld"
%attr(0755, root, root) "ROCM_OUTPUT_DIR/opencl/bin/x86_64/llvm-link"
%attr(0755, root, root) "ROCM_OUTPUT_DIR/opencl/lib/x86_64/libOpenCL.so.1"
%attr(0755, root, root) "ROCM_OUTPUT_DIR/opencl/lib/x86_64/libamdocl64.so"
%pre -p /bin/sh
rm -f /etc/OpenCL/vendors/amdocl64.icd
rm -f /etc/ld.so.conf.d/x86_64-rocm-opencl.conf && ldconfig
%post -p /bin/sh
echo ROCM_OUTPUT_DIR/opencl/lib/x86_64 > /etc/ld.so.conf.d/x86_64-rocm-opencl.conf && ldconfig
mkdir -p /etc/OpenCL/vendors && (echo libamdocl64.so > /etc/OpenCL/vendors/amdocl64.icd)
%postun -p /bin/sh
%changelog
* Sun Nov 06 2016 Laurent Morichetti -  1.0
Initial

