#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1256408070"
MD5="8bcf90de36590ac168f1da76eb564323"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4021"
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
	echo Date of packaging: Thu Mar 31 11:00:30 CEST 2016
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
� .��V�kSG�_������$l	$�������*$��R-�#�a_�0!���=3�Dv_��.F;����w�\c�ų�-loww�o���V�o�^4[o޾m����}�b�����z�/�������g�r����O[c3`a�5������Λ�f���Vs�l��������l3E)�d��:�|��%�LQF����x�9�+�+-`�f3P+[jM�M�z�8f�~fHa�<�a�9��O�?�ە���^�ru͚�A8/ ON3�����
Kn4<9駀�s���ަm�7	W��F���H��!��Q�o��gE���{�<���'��&��w��ӟ'����"�e^�U
@��t!Vh��r���O>�S��kEQ<�t�ɌY^������tO�+g�v����2�u8w��t���u׶Qh/D�C�g]��s�[�N� n���pf@ݢ+�����B��̿e>�}�.\1�f@�`S-�B��ZB#@��V-G�z E�(��3�vB0�PK)X��E���+7`�l0s� �}�C�n��L~�8�_yb����`��k�K�>`A��2O��I��u-��]�3b��	u�iN��^x��d	J|�L��WH�PM�e�4?`���Be��)w3�bp~���T�݆�\^�>n<-�hĸ��%i�x=�[*�KA�@-��<kV�"r;炄[
F�Q؞���copt�q2�����������n=�y����C7�#�~�Jg��� �S�T*�kk�,���y�߹�+��7_2�F��b��+��s3�p�2ԭ�@"�j��/�g.�=Gw}ҕ�R4��]5L]-2�~�<չ�m�JVr��L��c�F� ћxZ8����2|u�.m�jl�\Ūq?���2H�r�����^0��ص��w���'a=�$�0>6���4(Bi�SP��z���w�2S2e�vC�1y9�=B��Il"�v�ꄣ�|	�}��Cc3E!�J��^��nD��O�O[[F�i}R�٭f%Ҏ����7��	
��ܠH���7(¡���s�L��M��<'�dа�F/�����fPR��GJ��T$x��J_�F] �kⰞi�8P>��Ŀ�֙A�?5Q�;���v���{?{g�`ggG�;S�z-�e2�Co4uO�NN�����\Z�|:��3r��7��O�Aw|49<�o��b�!�ȠIx�=�����.2�2�cC�����L�H�12�Ң����"�T3��gEPb��!���u/�h��++���绡�c���z��ڃt�mi��;���!�{A�TO@/��/�<��l������<Z�,z�4��L-�:�����;�ޏ]�u����/�����a��Q��hW�Pe�J����X�6�ǙuH)4���R����/XL��ȅ���,�@(}�C�E�{n20ut\�P�G�@�D?+�u&�D��R�V�𿕂V^!i���D͸�8.�X j�,H�W�?�Z��t�Or���,-��b-��/em抪���܌Ј�aL�M�2��v1�J9P�++�d0b�$����r�w�e��
�ÀYS2�.�X5ً����SbH�bnM�8�3�]K��4����~e�fS���N�;v!�?R8� 3���K	lC!�<tm��q"̬�(�׭�@�����t
%5�24�tZ��6�?,�;�]*@~v#N�`�}�\�F	Fhꑥ�YI�AB��g��s���[% <O#p���zj�A�q�aj�#����'C���)������d�ɂ9r�GwB�z|l?Y���JK@$��G�4q�g����� �A\�a�tBT]$��W�Ȅq��"*�D�
-.*L&���5+p�$�~���\߀��p2>��O;}���|_\�	�Ď�7�Ky�J/e5�a#&�!��(��|w��Kd.��
����3E�s�(���`�xb�N86��r��B��P���-(!_��tov��op&�ɬ5�����!E���L:h�e��0r%]pm��dN�v3�	�IӤ	/8����&B�.9�x�Z ʑ�Z�6ʱm"aq���3��TYnM��c;R>ǦS��M�M��
�<nk�F!��Ǐ�ᦸ��PE].��MqCv�؛��~�f��Vd~��O,��D�n�jZ�/��J&�O�h����s>	]]�^\_R��c?U>����g>�j�%�'���!��]T��[]TZ��]T�������
J���t�5W��ϒ�8Ζ2��|Q�&<~C���e��r<��X� ���gy�k��O�!�'kT˓Ų�1�J�ɖE"'��C�<,̮(N�B��ϓ[�eUA�$��gTJ�	�*���t�$�9���+
*��"����+<Ku`4>��*�_T1s�E߄��^�
�\��"ۉ3U�!�X��5a<T��������V� ���0&&����W�D~�&�|�*����xLR��2��wr �7��� ��$�z�r�|���]���qo��U
L���3ߍ�g^$�� �0�C��y�g�Z�N/S �=ðs�9A9e�ud�����'"p����uG�J�� �o��7uK�b�+��h[E���J�oB3���!Y�<�c�����O�0��A�pF|DnO�s���=h����"Yb��ʳ�&4Kj%�U(a��Rp.n�������KD?x�B_�r���^خ�[ޝ��,q=��rT��Wę�1��n����*��?kED���	�a����q���F䈸��j��������6~�Ùa�	����oJ��m�L�%�O�D�h�p�9��	cFY����s�{��d6%�'d�B�v��U��p/,'��#�������Yx�LT��~�C����Ǣ���ˣ��*�j��l�$�
s�5T��P�n�M>غ@��-x��e�f���8���ͅ���қwz���"��fa����u�Oz��q[�ץM���9W��bc�S�܊^��瘻���"3'�8HX.`�1�^(�ּ��|�$�Ü�/��������y�	�I�4����A��_�m%���� ٗ��=B� .��Y�-!��m�1�Ƽ�r1d��z�y#���{Z4ކ�l�^���QG�7=Y�%�w����pR{��׊n�?��˫ɌTh�>�)�1���D�ʃ���oԒ^��.�RS,�<g��[b�HL\*������U�__��9�;jk��۽֜�ʳ��=�n%~���������߭����6wZ���EK_��e�4t�SJ�Jt��QUi��p��Os��#']���yO���'�P������4F���f��?Ɔ)��%c=	f+/�����<_���nn��{{��Z��������ð��ؘ(i���
M��{l-����"\��1����Q��qw�1Y�x��0��Ύ'b�w(&���x�~`L���7����o�/kʃR�!�u�C~i��ѾR�[@�{0~�?Ə��_z(Gb�Fx�A�.Ie{ѽ{2��4��1/������`o�Ll��ov���Jʧ��z�5���G��_��x���"T?��z���g��-�WG��N_��t�j�VJ��z5;N������ttT��#+`���"'�r� 5�!���Z.f���~Dy�yAz.�B܈^��l�L��y���_s��x�j�I�S��fr*��]N$���+zXM�F92��t�E|�ԏxҔ���=���k�?'���\N��t�_�ܿ�܅�b��^�_t��%��B��m��4�i�Jq�W�{N�ȓ(� a�����+�?|}O�x�SM�R[����B�kX����
9a�bt�^�|J���dW\ ďd����k�\����nq��`��"�E��=.��xbݯ!�P M�彩xԟC@ϩV�Ϫ�R1��~�O��%�����d�w3�j��E�>#�!ݚ�C�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[����zX�( P  