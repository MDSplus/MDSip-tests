#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3731806791"
MD5="1e320645e1c55ba71128e97630b4821d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4024"
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
	echo Date of packaging: Thu Mar 31 10:24:20 CEST 2016
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
� ���V�kSG�_�����9�`_��E�QEqr@���ڰ�����랙}"	�g'�*M]�v�����泯޶���ݥ��׻[ٿq{�l�z������j��Vskw��v��-
B�x�9�ϴ�pO�����f���k����������[�&�k������m^��f0S�2�f���]?PP2��etx����n�R���h6�������w�c��g���s�Ɲ�w��䧓Ѹ]y�|�-W׬������4L_{����FÓ�~
�?�ڛ��m�F`z��q��h4쟍�:2_�&_�xV�	�7���9q�J�h���x�9�m2�*Z��^� ��Ab���(G�N��]�05˽V��M'�̘�Uk��Zo�@��rh�l*)s�^�s�M�	.�\wm��RQ@49�EK>g��4Q�v��gf �-�h�i;)4IK��[��g���(`T6�"+�,�%4�x�k�r4�P��B�>�n'C��R��)�[$�k�r&�3��7=$�F���W���'V<�z�F�&���x�1��a��$8���\��b,����8#v-�P���䡙���K��ć�t<�{�$
դ\O��m�/T����r73-���M�m�o��%���ӂ��A���Z���ף�����������ǳf�a)"�s.H��`d��9N��G'�'�޿�����ݝ���ӘG����pC?b����tfN?� =UJ�Rθ�V��O��^��E_�W����6j�;-h�b�:7s
�P)C�
�	$Ҩ&��2}��st�']�(E�PޅP���Q��"���S��چ�d%��m<�i�p����3n�̾!�W� ����6�U��#�)�d.'\����3IȀ]�hy'��{�c�@����`C�9O�"�f?5���/P�
x�!�0%Sfk7dn���3�#d0���&ґj7L�N8������=46S���ʰ�嚠�w#�}>�/���p���d�[�J����o&b�P�A��9|���^�9G��c��10��󜌓1�="*�"DhP�@}H)�6P��+|�;u.��z�Ak�|�	�o�m3�t?�Pd�_gCHx�B���7D�6tv4~��e|K&y�&���/�����`����B���c��������ko�MOo۪"�@yH|rf�{��~����E�]F�"8lH{��r�I�:F�YZ�a��wT�j���Jl�C41<�q��em��ve�М4��|7tu)�QBOB W�A�O7ݖ�=���̰p���I���q�]��CHA���qo�M��C��)�r�G�@�,��Ү�<�������҅��Q�����_x�&)�C~�v��Uf���++�e�Bz�Y�_��B�Yh(%�����D�I\�-�̢h�R8Ӻ��D�Eoy��H��2��]�a�%�//eh~���[)h��^:�@Ԍk��R��vςt|�S��L��$G˟���*֒s�T֖a������*��X�T��*��l㩔�e뼊�O���L��y�.�xgZ�͡`9�5%���T󐽘jH;%�(�ք��9CߵD��A��Z���滀`6U�����c��#�è0�ǿ(����6�Cצ�'�,��z݊�{�,M��QÈ2A#I��_�kS��2�S�e�4�77����ǻ��h�L��Y��Ցt$�a��|��<�)�U���1�&���͡�����f:bO�Y~2�i:��XNI�,��c �}t'���Ǧ��%@[k���D�{Ix�ɹ ������O'D�D�8�}E�L��} -��A������d�{I_��OB�7����8�'�I��Ӈ�����e��H�x)S��w��RV0bab�}2[�Ro��p�9�����P�X8S4<0��r�
v�'�c�� -�(��5(=ނ�yL7q1�fG����ab��P�lA�iR�=���Τ��[����b���N�$i�1{j����4M�����x1;o"���#�w���(��k��&ǋ�8��K���D�>�S!�nl:���D�4Ȫ���fn"Ky�H�n�
U��(�7d�`��Iz��a�`�ޱ[aE6�O��ĒMD�����r\��d���:&./�5������u�%��<�S����|t��c+Qx�6�>0�I�E�II�E�E��Ee�:l����᩟4߭L��-Qs��,I~�l)�)��g��7�^�9/�>����x�g����By��<Y,��2�Z���,9�ĭJ�Eg��C�<,̮(N�B���_2��d��U�Uq�����F�
f$������Ւ��h�F�(p�q��#��>�8�U�����3+bQu��z�F{+�s�R(�GU�!�X�ҕ`<T�����VP�2�?Q�%�����7�<~�&�{�)���xP��H(�(��n3�,L8MR��X2~wփoP)~��<��ݶJ	�p���̋D@F��`�55�#_�P�W�e
���cvN;�#(�L��L4N��Bξ_:���]�V!�)u��niW�B~EWe���]r]i�Mh��s>$��'�rl����	�6�Έ����2a����]����#�C��Sy�߄fI�d��
%�ۂV
��M����\8����>x���[��o��ە��1��6�%.g�s�*��ʃ8�9����|��/v�Ҝ_+"��O`������6�0"ĕ%U���̽S�w��l�+M�>g7zS�dn���{P����C�@�P
��P&��1���G��9�/���J����1�ӕ�[%�l7���xvjT����O����ޫt��^�{X�Wܨ�(�h�J�/5-I���a�!5�[zI��.Paq�?j��85G7���tsa�c����ǝޠh�HЅ�Y[�6��Gݷ�޸{�V�uiK�&eʕ�����T-�bC���1f.�pǤ��̉$���D0%�h��@�5���'_ ɧ.�g�K8?:y?�|y�uB�_R/�"->h:��{7F	o.8/H�%�x��N>�K���B�6v[|�ŕ0o�\�� �e��������1������v�Q�Nn��]fv���N�6b���{����j2:�E3�ዀu��/���`����������
����$�Y)�X)�_>ġ�>�i����{Gm�<���­3���F���}��jgg�������͝��߿��/U�2]��)�����L�(��4\y8���9T�p7��{������Od�n����h��C��|�%~�S��K�z�V��ۗ��<_���nn��{{��Z������������ؘ(i���
M��{l-����"\��1F���Q��qw�q[�x��0Ö�Ύ'b�|(&��Ø�~`ܣ�䷣���o�/kʃR�!�u�C~���ӾR7^@��1�`��!r��P��@��+]���:�{7�d�i��c�^*�ţ�;���0���68�r#U��O}	��KP��jm��=p�L7��D�~��V՟��u'[���z���@70�&֠����jv����'WK��
!FV����"'�r� 6�!���Z.f����Dy�yAz.�B܈^��l�L��yњ�_s��x�j�I�S��fr*��MN$���zXM�F92��t�Y|���xҔ������k�?'���\N��t���ܿ�܅�b��^�_t��%��B��m��4�i�Jq��{N�ȓ(� a�����+�?|}K�x�SM�R[����B�kX����
9a�bt�^�|Jw��dW\ ďd����k�\����nq��`��"�E��=.��xb�/!�P M�彩xԟC@ϩ��Ϫ�R1��~�O��9�����d�w3���E�>#�!ݚ�C�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[�o����� P  