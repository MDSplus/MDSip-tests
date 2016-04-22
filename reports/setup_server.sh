#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1259825078"
MD5="c30d05d217601188ba8d753de8e170e2"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4056"
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
	echo Date of packaging: Fri Apr 22 15:30:28 CEST 2016
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
� t'W�ksG�_�_�Y8�	$�W�хHء!J�89YE�v�ѾnzD�_���S���JruL],v��g��=3��|��m���]��|�������ۭ7;���7;/��[;o[/`��Т �|��c�L[����hkl,��F0�����y�(�Vk������V�f��t6�����ݙ!�0�w�@À:S���io8t���J�R����ʖZ�c���)���R؝��!�;�����'�q����k[��Y37����i�����@e)�''���7C�۴���&!#����h�?�u>d�8
�M�B�(�xo��s>q���G�~����O�ag�}�2/�*�d�+4LE9�u�'چ�Y(�o:�d�,�Z�E�Bx��'@�b{PIe�:��^h�Np�kۨ���ɡ��.Z�9��^��j�+T�pf@ݢ+�����B��̿a>�}�.\2�f@�`S-�B.�ZB#@��V-G�z 5�(��3�vB0�PK)$��A���K7`�l0so!�}�C�n��L~�8�_ɱ"��0�!�蒻X �c�;�a��$8r�t�bh1���zP��O�[Ls�����{�%KPb&39|��F�����i~�@���62?�Sng����-��B�����}0�xZ��A�q3YK�R�z4�Tח���Z:���x֬6,E���	��ܤpA���������d��w���������z���هn�G������1 �S�T*�|lk�,���y�߸�K��_2�F���b��+��`�3�p�2ԭ�@*�f��/�g.�=Gw}���Q4��](5L]=2�~�2չ�m�JVs��L��c�F� ՛xZ8����kr|u�m�jl�BŪq?���:H�r����^0��ؕ��w���'a=�$�0>6���4(Bi�SP��j�n���2Sre�vM�1E9�=BS�I|"�T�fu�Q_�\����)
yUje��zMPˇ�~;�����r���f��J���ӯ'b�TP�A�
7�o0�<���U�H쒧M��<���Ұ��8�����H�oP���Gf��4%x��f_�F] ��Ⱎi�BP>E�$���A`j����s�I/X3�~��v��Ύ���p[(�d���h2���=�������*,����	f��O��{���hrx2x�V���C#P@���{���}��]��e,�Ɔ�	-י��cv��E{GEЩfZ�ϊ�$&b��i�̷u/�h��K+��9�绡�c���z���5��t�m���[��Ȑ׽�Ȫ&-`��{(k2!9�{ǽq7e��J+K��@�D#�FY���]y�u��N��C'G�~�'�����ig��fT&�ڕ�34��R�!�8��);��� )����PJ�R1���r'�[��EY�p("�u�]����Q*�hh�ke�����D�(#^^��a���R��+4-2�t|��W�˥T���*��P+$���I���\��U���-�\Qq@�qF���0���Q�1��v1�J%P�Y8g0kϤ����r���ea�J�ÀYSr�.�Z5ŋ����SbH��nM�8�3�]K��4����~a�f�I��5��w�B���pX V��5�>؆B�y�ڔ�DX]_R��[��
}y���Nj�i&h���Kve�xXwʻ,4���F�����x������#K�6�΃�4L$�ϔ��0���J �O�pR���zj�A�q835�{B�r�P��D�J#�aep8Y$E��F��R�1���MC��'@_k���D�{I��/(c`&��q���蠑�Nd_� 2$EH���G�+�Z\T�Lt/�kV��I���ߺ�ǝ�d|2�v�p;3���n�?���΍^�j@�F,L,"�BfU�M�n5��a���F[��s��7h`Wȱx'�i9(E���"����#�k�n�b�͎���n�$<Y�ك"D$�iH���j�[�ͷ�Y�-f�d�-���IڮcUՀ#A#�4M�Ȃ��|1;o����R �w��HRx�F=�M$,؋�8��K���D�>�S!�tl:�j�D�4ȫ���fn�Hy�H�a�;
M��(�wd�`��IzX�a�0soٍ�"�+�~�I�&���������������ۚ�g��Bt�!��c�%��y짎>���>���3��<3`wL�|-��Ҥ��S�EEا�6�u؂���ËA�[�.y���|D곤(���L�0_T�����2x��O��"V��+��U����n9���9��b�,k��4���ˢ������'�>,���NE�BH���S]��ɂ�)H2��:/	f���̹���ڄ�4�'W{���O�nW~���g9!�O����:9sŅ߄��^!
�\����$S�k���*]�C�}��l~�uo�RS��g�a�������ᄧ��@{�G�l��$�a���q�3�,LR8M2�g<V�pփ��q|�9�׸7�w�*%'�p�FW3/I u	����Լ�|�B-^��)	��a�9����
�*2�IY��	�	\|?t�g�Q�R�<B]��u��.���.1�VQ�%������-�}H=O���(sU.&�� �kmP?9#>"�'�s��p{�܅�-�G8�:��=�W�Mh��J&.�P¾-h��\�|+Ε�[�탗�~����vMq��]���C�h#Xz��r�<��1�n�����*���kED���	�ab��9I���F����f� ��y���6~�Ùa�����oJ��}�\�U%�O�T�hQ`&�	U�H�������4�'�)A8>!�b��@�t~�Ga9Av	T�L5�"*g���+�_q��},�/]�<J1ڪR���-�Oi~�5t4��
�Ы�8�J[��Q��-��)�8���͂/���hz���n�^����ZhS��}?鍻�m�^�>�nR�\i����N'�V��w���OwL�x̜H� a��yL�Ĉv�Ih7����J�Y����ΏN>.^�w���T�K�H��N�垚Q����})��$���������cq}̛*C�+��G��B�(��E�mh̦�%p�u�yۓ�[�}��_�'���Q�Xp��������J���Cѝb#`]�PLT�<�X�z9�F-�o��=5�2>�sV��'V������Ou�ԏ�y�x���A�{Gk�<|�ך�$Z�����kF����}�����w�m������Z���#Z�De/�¥�{�R�V���ȴ�¨JÕ���C�E�ʷP�&��������ul'�?��	=o4�E��16L��g,�I0[y�n_���r��{{�m����wެ��y���;̣]a��ف���a���дY����Y�>�,�%`JN�`u?w��u����s*j����x"AF�I�b�<�p�f1�k~�	������<(%�\�;�WE��+%q��"����c��Q���r$j�7�&�T��ݻq(oKC���R	]��	��ȇ�FH���a����d}�k�7_�:�~Tk�E쁋L�p��6���f�[U�?�Нl!�:�}t��g�K�4�Q��vGyJ���bH��K	g:�$�qgR�bQ<���k)m-d��
X����	��0��1,æ<O
��'��oj�X�n����X�;/��_��c�X�����|��_s�t� n8�$�����֛�
�y���y���w��R{{:]d�{�G�O#q�e�����ɭ}�%�Sd� ��g1��8wa��)�������\h�1�M2��f�w�zſ���Dq�����_)�YP��$�7;�d+�E�8�*d����\.���-F7�EȧtE]Mv�B�H�+����v�1X�����
a�.�LP$ݯ�g�Ǧs��-^�X�k��}-LGP6J�U	��?��(�9��j�nL�w:�e?�dw:�iTN���q;��\���H�ga�;dh�u��n�n�n�n�n�n�n�n�n�n����m� P  