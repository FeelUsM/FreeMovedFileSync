# syntax=docker/dockerfile:1.4

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# --- Системные зависимости ---
RUN apt-get update && apt-get install -y \
	build-essential \
	wget \
	unzip \
	pkg-config \
	libgtk-3-dev \
	libssl-dev \
	libpsl-dev \
	libidn2-dev \
	clang-20 \
	g++-14 \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /build

# --- libssh2 ---
RUN wget -q https://libssh2.org/download/libssh2-1.11.1.tar.gz \
	&& tar xf libssh2-1.11.1.tar.gz \
	&& cd libssh2-1.11.1 \
	&& mkdir build && cd build \
	&& ../configure --quiet \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& cd /build && rm -rf libssh2-1.11.1*

# --- libcurl ---
RUN wget -q https://curl.se/download/curl-8.15.0.tar.gz \
	&& tar xf curl-8.15.0.tar.gz \
	&& cd curl-8.15.0 \
	&& mkdir build && cd build \
	&& ../configure --quiet --with-openssl --with-libssh2 --enable-versioned-symbols \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& cd /build && rm -rf curl-8.15.0*

# --- wxWidgets ---
RUN <<'EOF' sh
	wget -q https://github.com/wxWidgets/wxWidgets/releases/download/v3.3.2/wxWidgets-3.3.2.tar.bz2 \
	&& tar xf wxWidgets-3.3.2.tar.bz2 \
	&& cd wxWidgets-3.3.2 \
	&& mkdir gtk-build && cd gtk-build \
	&& ../configure --quiet --disable-shared \
	&& make -j$(nproc) \
	&& make install \
	&& ldconfig \
	&& cd /build && rm -rf wxWidgets-3.3.2* \
	&& cp /usr/local/include/wx-3.3/wx/settings.h /usr/local/include/wx-3.3/wx/settings.h.bak \
	&& patch /usr/local/include/wx-3.3/wx/settings.h << END_PATCH
246a247,257
> struct wxColorHook
> {
>     virtual ~wxColorHook() {}
>     virtual wxColor getColor(wxSystemColour index) const = 0;
> };
> WXDLLIMPEXP_CORE inline std::unique_ptr<wxColorHook>& refGlobalColorHook()
> {
>     static std::unique_ptr<wxColorHook> globalColorHook;
>     return globalColorHook;
> }
> 
258c269
<     static int GetMetric(wxSystemMetric index, const wxWindow* win = nullptr);
---
>     //static int GetMetric(wxSystemMetric index, const wxWindow* win = nullptr);
259a271,278
> 
>     static wxColour GetColour(wxSystemColour index)
>     {
>         if (refGlobalColorHook())
>             return refGlobalColorHook()->getColor(index);
> 
>         return wxSystemSettingsNative::GetColour(index);
>     }
END_PATCH
EOF