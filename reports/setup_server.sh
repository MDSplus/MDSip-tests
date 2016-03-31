#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="4017264067"
MD5="1eb6481ce1ef3ada1c58c85203ea1f30"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4020"
keep="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
    while true
    do
      MS_Printf "Please type y to accept, n otherwise: "
      read yn
      if test x"$yn" = xn; then
        keep=n
	eval $finish; exit 1
        break;
      elif test x"$yn" = xy; then
        break;
      fi
    done
  fi
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.2.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || type md5`
	test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || type digest`
    PATH="$OLD_PATH"

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 507 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 24 KB
	echo Compression: gzip
	echo Date of packaging: Thu Mar 31 10:41:58 CEST 2016
	echo Built with Makeself version 2.2.0 on linux-gnu
	echo Build command was: "/bin/sh \\
    \"--header\" \\
    \"/home/andrea/devel/rfx/tests/build/../MDSip-tests/reports/setup_server/makeself-header.sh\" \\
    \".setup_server.tmp\" \\
    \"setup_server.sh\" \\
    \"setup server script\" \\
    \"./setup.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\".setup_server.tmp\"
	echo KEEP=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=24
	echo OLDSKIP=508
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 507 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 507 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir=${2:-.}
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp $tmpdir || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 507 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 24 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 24; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (24 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
� ���V�kSG�_������$l	$������:!TH���ZvGhþn`��_���I�Ip|U���Lwϣ�=s���޶���ݥ�ͷ�[ٿq{�l�y������z�b����v���
-
B�x�9�ϴ�pO�����f���k������7ۻ��Z[�/`k��go��6�Lg3�)J�'3����((Pg�2:<�ǃ�q�]�^is4��Z�Rkrlr�;�1��3C
��~����x���hܮ<d��ږ�k���yxxr�����?PX�p���I?�{����6m#0�IȈ�r|4��Fb��/��/�P<+
������8Q�4��~8��2v�?-�j��P JV���B�T��^��m���^+����Nf��5xPt-�w�{�^9�k���9P�ù녦��p����B{�( ��?�%����u��q�F��33 �]	��д���%`�-��3t�A0��j�r��<׵j9�(JD!]�a����ZJ����-�5\��d��{��w#_g�+Ɖ��+�P� F#�\]r�<�����xO�t�ch1���zP��O�[Ls�����{�%KP�Cf:��B�jR.����6�*s��`O�����sT��
�6�7����p�iAG� ��d-IK���P�RY_
Bj�����Y�Ұ��9$�R0����'{�����Q����������v�ị�gr���G��W:3�_v ��*�R)g\[�g���S���E_�W����6j�4]1\��9�s���n��iT�T~�>sA�9�듮d��g(�B�a����h�Q���MmCU��Me�6�4r8�������fߐ�{�wi�Uc��*V��ߏ�A2���|����$d��m�����/{�c�@����`C�9O�"�f?5���/P�
x�!�0%Sfk7dn���3�#d0���&ґj7L�N8�˗���=46S���ʰ��5A-�FD������e���'%��jV"���Ϙ~3k���:��T�:~�"�^�?��D+y���srN{l�2P��X��0�Aaf �! e8x�$��@E��J�����p�&��� �3�_H�+m���Se0����igHy�����wF�vvv4^�3���B^&s=�F�Q�������l0�>�U�ϧH0#��N��t�G�Ó����� 6P�����ޣX��{��"�/�_06�Hh��$�t#�,-ʺ`�;*�N5ӊ|V%6�!�2�X[�2�6�@��rhNz��:���(�'a��ߠ=H7ݖ�>���̰p���I���q�b��CHA���qo�M��C��i�r�G�@�,��Ү�<̿��a�������n���E_��3L�2J�������\)q�V�چ�8�n� )����PJRS����r�[ښE�p(��u�M����*�h���ge����Ä�(#^^��
a���R��+$-2�t|���ǥD���*��P+8���I������U�%�-�\QQᕛ�2��6 �)TF��.�X)g��ye��F��d1b�|^n�δ,t#�Ct0kJ&����!{17ԐvJ	P̭	�s��k��|����P������TE@���S�]���3������G�PH<]�"a�3�+
�u+2P�����4�BI���$�ŮM���Ny��
Ѐ_܈3�s���Q��zdi~VG�y���a�����4�V	 �S���{�6���~r~���=!g��P��DhJ#�aep8Y$E��F��\�ѝ����O� m�m��	$�$M�Y'�<f"nW`>�U�{�D�12!C\D�����{��G��
���%}�
\>	�߰�;�7�3��O&���N�f&��m�"���My�R޹�KYhX����E�A�l!J�)_Ý���Kx�B)bm�L����:��-*�5�X�������b<"Ԡ�xJ���1���ěu��\��y2k�E"D$�iH���j�;��o��;�\I\[p;���]ǌ�G�F|�4i��.��켉P��K� ޹�r����rl�HX/b�fx/U�[���N��ϱ�2ye� ��*�ۚ�Q�,��#�G�)n(4TQ���tSܐ݃!�&�a���s��{�n�ـ���Kz4�۶���q������+�������OBW������O�>�v�م�ϭ|F���z��t��b�&�V�%a�m���{����|�2]�E�{D�$!���L�0_��	���2x�O��"V,�+��Y�����r����d�,s̸��G�e��I��P���+ʄS�.�|�����eYUwI����`F���x�>]-Ix���m䊂�Jk�H�����Ǌ�R�O���J��*f���7�+X���r@d;q�
7�+U�&��j���9����ފ���������~�3�����߄��C�����I��P�Q�ND�fY�p��X�XN�pփoP9~��k���m�48��w���h$�:�����kj^G�������u�0�v�GPN�v�h�,<�	��}?u�g�Q�R�<B�[��M�Ү�����0�V��%� �����-�}H=O���(sE.&�� �imP/��ۓ�����n������GV�ؿ��	͒Z�xEJط�����oe��p"|+�}��^���ܮ)��+��wg�mK\Ϣ�U.�q�s��������Js��ZQ��x�E��lx<E\�1w�9"�,�Z.pD�f�2>���d�pfXi��9{�ᛒ&s�8%�tE���!Q Z(�~N(#FQ��#���y?�M	��	���;r�����	��H��*g��c^9U=�_����f��h�t��(�h�J�/7=I���a�%5�[zm��.Pqq?j�ٸ5G7���tsa�c����ǝޠh�H���Yk��6��G���޸{�V�uiS�&eΕ�����T=�b����9�.�tǤ��̉$���D0E�h��@�5���'_)��0�g�K8?:�8�|}�uB�_RF/�#->h:��{[F	p.+8/H�%�x��P>�K�f��BK��v[|�ŵ1o�\�� �e��������1�����/{�Q�MOn��]f~�;��^��8b�����O"��j2#Z�Es�a��u�1����`��������������$�Y)�X)�
~�Ci~�k����7rs����Zy�~��[�*���F����}�����w�m�������~��5Z�Re/�Х�{�R�^z��ȴ�¨JÕ�ß�C�9���P��(�{��?���ul'W��1
=o4�E��16L��g,�I0[y�n�������vsk�����;[k��*��c}�a�+��1;P�� 4L7��6���Z8+���E�L)c�Iw����� c����a��-�O$Ĉ?�PL~���.���F�oBaߞ_֔�DC��z���C�}�$n��D�`����!r��P��@���&]���:�{7�d�i��c4^*�ţ�;���0���68�r#U��O}��kPݏjm��=p�L7��D�~��V��>t'[���z��@70���ՠ����jv����'WK��
!FV����EN`�6�jnC�7�\�47�9t�,����\����(�w�5������ �!�$R�������T�ϻ�HbϫW�����rd���t�����)��{0��פ8Nn�,� �"#z�ܿ��Ź��N1���$���KzI�*��$�i��,���W������'Q\A¸#z���W����x�f��l��'Y�,װ��er¸�覽��ɮ�@��|r��� KW���PU���E�	�$��z\,�c�2ĺ_C<�@�F�U	�?��,�S�F�U��b$���3�j�K�IG1"!��0v7�f�Bb�$}F�C�5_�b�n�n�n�n�n�n�n�n�n�n�`�K��6 P  