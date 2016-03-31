#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="4234171318"
MD5="71af33285f3b4bb19670eec11a041e61"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4018"
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
	echo Date of packaging: Thu Mar 31 13:55:31 CEST 2016
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
� 3�V�kSG�_������$l	$�}dG!TH���ZvGhþn`B�߯{f��$���JS�����~��56�=y���fg��6��le���Y���͛Vsk������֫�;�`��_Т �|�g�c�L[����ikl,��F0����BY��j��~[k�?y+�yi:��LQ��>�!�0�w�@À:S���Io8t���J�R����ʖZ�c���	���R�G��CwN�wǓ�G�v�>�۶\]�fn����0}����R����) ��mo���i��MBFĕ��Ѱ:|�g�8
�M��xV�	�7���>q�1��I���I���ɰ3��o�����P� ]����:���m��,�JQ�7�p2c�W����k!�}��w�i�]�]��2�z�\/4]'��3ݵm��E��P�Y-���Q��D5���A83�nѕ@{M�I�Ii��0�:C.D3�j��Y!�d-� ��s]���A=�E���v;!Z���
�N�� Q����$��[t�����:�_1N�W�Xq��0�!�蒫X�F��M��ƣ�S�sC��tF׃�صxB�b���f�ޡ,Y�o2�q���(��r<��A�ЦC����̴����7Uh�����O::1n&�$-U�CqKu})����{{g�j�RD��\�pK��M
t0�|��?LF��t���;;�^m��<��p�>��{ ��ә9��H�T)�J9�Z=�>k�z�����z�9SmԾ�4]1\c�9�3���n��Ri4�T�>sA�9�듭d�����B�a��h��Q����]mCU��Me�>�4r8�������f_��{��l�Uc�*V��_��Ar�n�|����$d��l������=
�1f Y���i��Ϝ�AJ���EW�T���f�8 Lɕ��5�[t��L�La&񉴥�5�������_���LQȫR+����|�˩�i�e������n4+�v��gL���'��J�2n�ߡ
�����"�J�4��󜞓C���*�"MhP�@}H�	�6А�}�;u��a=� u�|�I|��3��j�fW��)/�{?ye�`e���+S�y-�e2�}o4uO~�LNN����\V�t6��3r��7��/�Aw|898�k��Lb�>�(�Ix�=�����.r�2�	cCƀ���L�H�13�Ң����"�T3��gEPm��)�̵u/ôaڥ�Cs�|�����1�LG	=I\��A����	ĭf���Ȑ׽��UM:V�(�P,�܄�t�����t<TZY,z 4��L-�*�����;���]v��_�/Ɗ'�aR�Q��hW�O�d�J����X�7�ۙH�4\��R����/XL��ȅ���,�@�|�E�;�2�tt\�P�G�@��8+�u&�D��Z�^��񿕊V^�i���T͸�<.�X�jw,H�W�?�Z!ɔ�G%Z�|�PV��b�状sEU��?��+Ø�d6���3��+�l@<?`�;��x&E�ؼ��K�5-È�P̚�wyŪy(^�5��C�sk��ᜡ�Z"%ߠim-�g�;�]@0�N���锺c��#��J ��ǿ�����6R�צL'�����|݊T��;�,M�TR�,3A#M'�/ٕ)�a�)�� �qbs��U ;��G��gm$�	i�F,�)?�AJ�/� p?u��I���ks��!�ᛩ��XJ��u�N��4�V��ER�n�(e�	���i���	���f(=�@�A���u�/(c`&�����i�萑�Nd_� 2$EH���C�+���T�Lt'�kV��I���ݺ�G��d|<�t�p;3���n�?�,����Հ��`L0�!��*����[��Gd�.��
����E�s��7h`W�c�J86��rP�B�q�Ђ��-!��c���ċu��܆Ix�j��D�HBӐ��qn�[�6�/��[�\�\[H;���]Ǌ���F��4i"�.��켉R��K� ^���H�-\��6���^����N�,�&r���
��c�)U�&�A^M�5s�E��G�G�)�(44Q���Sܑ݁!�&�a���}��{�n�ـ?��Oz8g�m5=�/�'��L���Ԭ<�����/9��c?v|��g�|p��pd��y��t��b�&�V�a�m������/��ne��E��;��ϒ�8��2��|Q�&"~C���e��r<�X�"���Wy�k����!�GϨ��eYc�'�_S-�B8.���:�<y��_X]Q%�
v��3/����.�SqG��ϟpR�HQU�oק�5	��4��\q����ZW{|���������/<%��N�\q�7!i�W�B9"�(v�L�)2V�tM����s�5���3H=���O$ă~�3�����߄���@����I��0�Q�N���4�0A�4ɰ��8��i�A���s�Ӹ7�w�*%&�p�FW3/�H u	����Լ�|�B-^��)��a�9����
�*2�IY��J��~��O��v�Z��0���뺥]2�]b���Ktv��סZtz�0=O���(sE.&�� �imPϝ�˓ǅ���s\4w`gs���W�U�%����*��oZ)8W7�ʂs�D�V~{�9��?oa,|�]S\/lW�-�������E/:�\�+�bO�k����{~������"�|��f�01��|��hc�
#
D�XR�\�H�<Jebh?ɏ�̰��q�p�7%K�>qJ��ݧC�@�P���PE������W��9�=�~r���2}!v;�*A�x�dב@AU�T��,�r&�z|�2 |��ͮc�z���A��V�J5f7�=I���iKj�B7��&�l����<~�2t�yk�n������܇tUM�:�A�m�p�0�Bm����&�q�����ҧ�M��+Mu�����܊^�㧸����!1'�8HX20��`��
ϕ�vc^��|�$�Ü�/��������Y�	�A�t��|� t�/�Č
�\UpV��H�&�|Y�n��BO��v[|�ŵ1o�d�\WC�2o��Q|O���ИM�K�җ=�(�'���.s��N�/�c�p�����^MV������N1��. &�W�� ,p�x����7t���r��9���+Eb�R��Ou�̏�Y�x���ܜ󵣵V��m�y�<���#�Q����_�z���w�M���������_��'*��.����2�\F�eFU�����*o):W��z��8A^�@���m,ԭ##8���Pp�y��/�ď�a�>c�XO��ʳu�s�?/׿����[�
�����\��_��?6ѷ�O���}%�B�t�]�i�|�����]�Y�K��2&�t�8�?�0����Vؒ����DB�����wx���Lf���
6����EM�WJ4d��w�o�0'�SJ�Z�!� ��c��Qܥ�r$j�7�-�T���;q$OKC���R	=��	vwɅ�FH���a����d|�K�7_�:�~Pk{E쁋{��пm B�}�0����x��;�B|u�{?�����]H׭-�$p��W����?�\-���)�lY�6�����-3�܂8�oj�Xbn�p��Y�}g����=��(�w�i�	�1���A\C�I�&�O]�+�ɩ���9�Ğ/�E5	���������[P?�NS�2`��c�I�p8���X�!�"�z�ܿ��ù��N1���$6��zB�&��$�i��,���/�����;Q� �!=�������#Y�~UM�R[����B�<,D�rY��n1�i/B>���j�*��G2_�\���;���Rn�[�*��(3A�Ծ�O���z,fC���	��4��J��9�i�Y5a3��G�����:�)QN���q;�����H�ga�;d[�u*�n�n�n�n�n�n�n�n�n�n����T͒ P  