#!/bin/sh

tar_xz="tar -cvJf"
code=0
pkg_name="$1"

get_files() {
	temp="$1"; shift
	package="$1"; shift
	pkglist="$1" || pkglist=""
	echo getting $package
	for dep in $(pkg info -dxq "$package"); do
		new=0
		for old_dep in $pkglist; do
			echo $old_dep
			if [ $old_dep == $dep ]; then
				new=1
				break
			fi
		done
		if [ $new -eq 0 ]; then
			pkglist="$pkglist $dep"
			get_files "$temp" "$dep" "$pkglist"
		fi
	done
	pkg list "$package" >> "$temp"
}

case $pkg_name in
	src)
		temp=$(mktemp) || exit 1
		get_files "$temp" FreeBSD-set-src
		$tar_xz src.txz -LT "$temp"
		code=$?
		rm "$temp"
		;;
	tests)
		temp=$(mktemp) || exit 1
		get_files "$temp" FreeBSD-tests
		$tar_xz tests.txz -LT "$temp"
		code=$?
		rm "$temp"
		;;
	ports)
		$tar_xz ports.txz -L \
		--exclude .svn --exclude .git --exclude distfiles \
		--exclude packages --exclude INDEX* --exclude work \
		/usr/ports
		code=$?
		;;
	kernel)
		kern=$(pkg info -x FreeBSD-kernel | head -n 1)
		echo Making dist set from "$kern"
		temp=$(mktemp) || exit 1
		get_files "$temp" "$kern" 
		$tar_xz kernel.txz -T "$temp"
		code=$?
		rm "$temp"
		;;
	base)
		temp=$(mktemp) || exit 1
		get_files "$temp" FreeBSD-set-base
		$tar_xz base.txz -T "$temp"
		code=$?
		rm "$temp"
		;;
	# TODO: dbg variants, arbitrary .pkg file
	*)
		exit 1
		# TODO
		# manifest=$(mktemp) || exit 1
		# tar -xOzf $pkg_name "+MANIFEST" > $manifest
		# pkg=$(grep -o "\"name\":\"[^\"]+" | cut -c 9-)
		# temp=$(mktemp) || exit 1
		;;
esac

exit $code
