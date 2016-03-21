#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3194066456"
MD5="dd7ec3b95f2db2aa0fd019de39bad502"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3968"
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
	echo Date of packaging: Mon Mar 21 15:15:16 CET 2016
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
� ��V�kSG���_�Yt��-��W`qQ@&��B"N(ղ;BkV�{����~�3�O$��q�4u1ڙ~��\u}嫷lo���o���F�o�Vj��o�����Fmc����^�-��X�l�c�|�������� t����}�V�˿^{��K�������i��cEYvg���<��|5*LQ��'�ޠ�<j5��K�g�6a�7Բ�Op�0�Ԑ��\�`�<9l�����C�k�a9�f�?��{�')`��i��#��w@���X&����Mw0"��{�ӾX�C��C�[�!�
�)��{Y�)�'�t����'͓?�����<�e^�r@��L��0���6S��+EQ\ϴ��Yn�����-���)��v�v��H*8s��tl��tg2Am�PME������J�&*CԮP����EW�"4I �&5�w�<�	�d�̀��FZh\v嘆�4|�q�r�� �Q��c�m`h��P��6!z�Dq���$Y�܂�{��ĝ�ә��p���cyUr`�)�4�%w�3�GFG�w���Ip�i_E�b,��q!?#v͞P��fg����Q�,F���t��B����
����A�Њ��;��ش���M�Th4����M:�1n�k�[�^������\�LswwϚֆ����9 �悑cNg�7|������m567����6�Oc�~>=��^���_��}b;U
�Bƫ���O��R��E_b8��������5]1��9�3(�B�
���h&��2}�ڶu�#[IENQ߅R���Ѐ�#���(S��ڪ��5j�}<�QhsR���c��lrM���B6�M��S�X4�|?R�]���3f��>�������IX�1ɢ�����E(m��8���@��g�\�D�&w�����i���)��>�X�]3�:�/^�㠟��P]OPȫR[��/��l��}������'5��hV���͓�vo��WrL�3�h����U�}�� �]�{���[E��Jd���ph�5� �3���$m��Yqh3V���^1��X����ъ�_U�0T3#�{����������4�Wb�,��hۀw�Nk�S���Hɪ��ƴ{臺��W�4�k�AG�i�˃����&&�2���Ԣ��.���d\�����\2J�q�u�k��d��Oc�[�r�H��]?Ϫ��Ǣ�v��LH@N���Q{�JX�2o(��@�D#��i���]�Y�_[�^������V���Eo���ً*B����i�u2U
<����֝�3�hs�Ri�� @�\��D��-�ŬO	:�8e�s����v0�.�-#�,!tǶ�pī���2�#����-T���n2>CՌ+̔��v��d|����L���DW?]�9�E�%/���]���*�����щ��o���1zl�`�H֧�Zp�`N:K#6���oM�}�ٔ�>�F��^j.��/i'Đ e��pq8g�9�Hz�hډ�c��y ؄�t��i:%�؅��J�0����/j.}İU��skoTk�k�KJ�u+4P�/���4��5��4�ɮL��a$�x��P�?��3�}���Q
�zhi^�F�y��?,�);�~B�o� ��:渤�#ϙp�������L[�	%�9C���+���d���J��pB�z�6�O� }���' H�%H��G^�|A37�+0�8Dw$=���%	2&CR������;����E�D���f���Я����p������~��c���6A���C�`���襮�4,`���"�{?`�J�_íf�C(L����("k�Bѐav���
9�c�� -�(�Y���7g�|m.�M\L��~���m��'�B?}��$4)N\�Z��$F�-c�w��(ق3Ҏ�$mױf��q�&�e�ё\�R��J�9�h�/���p&��	�"6�h��d�7����T@��V6Q7�*h򸭱(R�?�zD��BCu�*�0��=bo���~����[v#��|�ۏ=��P��6��|{5:,�����#:W�y��-�f��J���i�4��S����g��ϭ˟Q�?Y��;�C��:/֨::/֩�:/nBE�����[�H�꒗j�8E�>sJNY[=�*��:KD�����K��x"��"E\0���c�˻�ʓ�@
v�r0:^T���4�_��,�<�ۛY&QQ�Hh��r�d�+�,jvq���
>�2�2'��KYd܏-8.PiY��6�|ų������=����WVC�hc;�3!8��n	�)Kt��w��d`��K�KԿ��~���~���7H�H��5�#�rd
���[%�#�������Fqxچ��(~n��:h:��J��E0���j�"��P����ڌ̫�Ӹ ����*%8����'ͣ>V��ЮBs�u�~H!���f��oK�A]~Ź�X�%�P^�%f�*J�@W8��~��E�x���.yń8}�5��s��G���q\�~���m���Xϑ��屮��A��S�J��m@=��&��ip��_O�o�@��uQ/6ˊ�����~`���ϬW%�����)���5����-�X��X�#�g	O`�	sd*<_!)N�6�>n,�Y��~=�2�'1���4�k�'�0���].��Fd�������K6t�6��B-�sH'Ɗ��?�+�t{��ˈ+A8>����+C�J��n=%����$g)c��}���*�����f�7����~�������mw�R,EKMq+Z�p�Q*B�}���ɀ��|����ʲt��+K7>�ntq�lw��]��Y����X���ۃ�QC�T�/��T�k�l'�ө�9���s�\��� ��J$,0��`��ϕ�vc^�љ|_#r���.����}���Y��wA��t��x�J��_�9��$�,����=Ґ)�%r���D�)>�7U.�\�A�S�[�~tÈN��؄��%oR�~�5Jn�ם�v���O�g$b��|x��|yeY�	�ۅ���E�:�i��
yR0��r�r�K��� zh�a<��s�䉉��/��P��3`�V�;���{Gk->��Sǭ�,�?���vͨ����_om�}�]S{����f���[����N�KUw]��痡i�Q������>��[����v�)��́J��Y�XG�|�=�����'�ď�a�c�X[�M���K�V���o�6�r���mi����d�o�Fq�1V�{J����d�s²=-�����<\��b2O����Q��	n��i�1_��vO����_�(&�o��~`����׵���o�.�ʃR�!�q�}~��y�RWp@��:�(a��!�e�9�����f��$��E�v��C����ҦP@�G�w��ra�п��-dFJ*��
*�W�v[���n�� O�l��D������_N[��W���n�#�L��6h+��m����h��ŕ::�B�z��R��	�̆0��l�C��F��%�
���Q�w�Ӟ�'��,��Тn~BO���ن�s4�{4�T����qE39��6�����%��&a�;;:]u�}�{�4U�}qY�E�����ɭ]�%�S�T/�����Ν�.v���������M$"�N�S��,�Η/������ȯ �='Y�+�?sr}G�x�U��R����,B�k����9�lts2��.�K�B��|9rM���"�sW�Y�P%!�Wy�	����=zc,�c�2ĺ_A4�@�F�%	�?��"�ҡ�>.�K�L�u�3~n/؝�jDJ��a�ގ5:PΩ-��Xz6��t��-۲-۲-۲-۲-۲-۲-۲-۲-۲-۲}����x� P  