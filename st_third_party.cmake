if(NOT SW_DEV)
  message(FATAL_ERROR "SW_DEV must be specified.")
endif()
if(NOT OPENSSL_VERSION)
  message(FATAL_ERROR "OPENSSL_VERSION must be specified.")
endif()

include("${SW_DEV}/stacks/texas_videoconf/thirdparty_binary_download.cmake")
download_thirdparty_binaries(openssl "${OPENSSL_VERSION}" "" 0)
