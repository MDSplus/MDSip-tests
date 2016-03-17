#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3795077729"
MD5="6cc0115dc2fdf76a7d203d7a9357ba5d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3948"
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
	echo Date of packaging: Thu Mar 17 12:18:43 CET 2016
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
� ���V�ksGR_�_�Yq�	d�W�хHX��%P������A�����C����랙}
��_S���t����g�����m�۝�[{������Z����N�V�o�mն^������_�B?�<�5�6<�-�{l���U7}�n՟�]�o��y������l����m��͑io�EYvk���<��|5*LQ���ޠ�<n5����3[�2P�[jY�ۧ8f�^jHa���0h���_N��F�>��۰]�&��r����0}�6��ʒ���NN:	 ��mlSwsj��;W����Y_��>�����m��k����۽,���U:��N������^s�K�2G���':<0LE9l7;'G��,�RQ�3�`8a�[*ý�k�{���ʙ�]�](&R�s�L��/�\w�ST�E��P�Y-��|�Th�2D��LL�[t��.B�h��y��.�����g�6�B+��+�4|�Ỏc�34�P���8�n; C��RN�	�k$�k9>�d��s��.wBOg�+�J��9TɁ�� �D�ܽ�|�ߚ6�G��S�}A��dFǅ���5B�b���fS7�CY�%b2ӑ�w
���:���3Ч�B���*7�bp~�]S�р�\\�N4-��ĸ�%n�z=�Z��A�--��{8kZ"r�怄[F^Qx����C�{x�a�o�������y�z��8�a�糣n�����N��1 �S�P(d\j}�,P��y*�\�c�՗L�Q��i1_�ñ1��c8��:T� j@*�f��/�'�m[w<���QT��](5��1꾏2չ���JZs�����c�6� ��Z0���W��*.d�l��&ŉe�^��#u����?��1g&	��)zޡo���u3�,J�xl�1�qP�Ҧ�AM���T��xf�8 �ɕM�+r��)ʙ6�!
��L�����C���T7�or���a��5A-#D�zj�lm)ͥ�I�eך�2~�ݛe����L1@.�a�.by�2@*=t�h2�VQ��Yf�uj<�uM�d&@��� H[`��mV���`�WL�sV|v8x��ٳj�afdt�oֺ�����pxp�}�P���}�^�����}J��i��2y�VU�И�c�P�1�JӢRz��<�X3��cyP�1�ČS����Z�a���ʠ�I:�zN�蘥%��GUG�B�K6ݐ�2���� ǌy���Q�A*�P��Ȅ��i���.�2�^�@4���[ڥ������5;��Z�=9lu��_��>�6{qUC���]�?�NgJ�G��Xںv�mR*���#�?�(w^s�����)����;n�Xy�ƀХ}�Eb������6�x�Z�~��������D�B�M�稚q�iP1G��/��D��Z�����4��L���T��0STE%��>:�uPi-�4F�MLQ��T ���L8)b�����iY�O4����g֘\��>�E�bi�!���U.�<��M;�}2��R��=M����	&Ҁ�3�Eͥ����z`a�j�aa:�Y�Bzt��锉i���h����4m���3�]@�pBN�`�]�\�F�y`ꡥyiI�AB��d��<	�U@~���z�=gʡǦ��3S3m�'�,�u�v��4�V
��ER�Nh(e�	���4d?y��S3���H y� iby�e�D� ��0<�ɑ���#dL����i��"tY��
��$}��>	�_���3��N����fn&&��m�"��g���R߹�K]�iX����E�w~��B��c����'L�6!�QD����!��
��5�%r,�	�F{AZ6JQ(1�-(ao���\����h��V�}��0	O}~��IhR��|���I��[�<�M�g*��IڮcAR�CA#�4M˂�#���捕�s
��5_��	o�LQ��&�El����ro"w����!6S!l�n�U��q['P�<���0���&�pU�a�;�;0��$=,�� ��87�Zx��̷{�á8�l����zt�WLe��Ftb<��6{D;�������'W�O-��P3?Z0�[�C��X�Q}�X�B�cq*:l��>�~��,��.yq�fN;D�h���}*ןͫ�D̮
Z)�Tx]�'�t+R�%�!�>�:��]�<zH��Y�(�3�e���*�
tq�����s*+	-��u�,T�E�-��,V��AR&Uf���ri#�L�{�%�J���lcq����7��I�+Ol���G\'���%�T΅X8�.��%��R,�eT4T�o��-/�.U���\� �V���_�/Z��@�4b���|����~����8�0�s��lGgm�����������j����E0��r�"��P���������Ӹ(��u�:%)�������>V��.Cs���~HA��f��oK�{A�~Ź�XڈY(�p���,��Hӯ3���>^�,�c��-�����������=y������ۃ��la���j�wU^נVP��p�B�����su��48WN�����_ ���:��e�q�F�_�z?�߂��vf��������E��
~����P��~,�壁G0�96����X�A��7��0'L��C����yD�5��K��w{c�d�����.�-:O�T�h�p�9��	c�U����3����eĕ ��c�ܕAX%�t7���xzjT���1܋�����{���{�kz���U��a�u�[�txz��GU)������X��(�#;U�^qd���TZ��Ǐr�njeY�Q����C7�L8n��ywE�.�<���]���[��A븡V*җTL�*�5u����dي]��)n.�p�d���%��ED��
i���vm^��| #_Z���.����C���y��wAծt��x�J�����4�<����=А�%r���D�->�F�7U.�\�A�S�O�~tK�N��ؔ��%�F�~�Hn��]�v���O�wb��|x��|yeY�	�ۃ�u\	��G�.���#�r9�F9�o~���r��9���+yb���ۧ8T@��W<&�N�m���Z��?��q���kW����}�������8��Y����-yְ�z�P�]W)�$�(4-#7��p�����gP|�#�OPi�.��?T:�HB�:6���'�����'��?�)~L��U{���Y����]�����v}����y���;̂a��ɾ����a:ٮ���l�T&9�;3�)�.ҵY�ut��b
�<�uZ}̈�ţݳ㡄��w
��o�0=������l����r�h�r���`&���EЂ�J�_]�#;Dђ^�ɑ�\c��KR�^[t�D�L�5�;L��x��|ww�1�� ��@f���񩯠R{j��A-�屻�tæ@�*��aPoI���5�B|��>�6;���,�D��R8��K�q��Y\9���)�Z>+վ����l��̆8�7�,
7P8t�*����\��8!=z��(�u�S`��6���A�C�I����+�ɩ��w�Ğ�/�-	������B��;P? ����!L��פ8Nn�	,� �"�z�ܟ�ܟp��v�SL/�/���GAh"�M��*�f�u�|ɿg��D~�����_)����{�śץx+�y�8�2d����\.ːc��G7��O骳�+��ϗ#��<�+��p5�uU�x����Hj_٧g�R=�/C��D
dai�]��3(���R�T̲Z�:�1�`�:�)QF���z3���2��H�cA��d[�U~�j��j��j��j��j��j��j��j��j��j��j�����ց}� P  