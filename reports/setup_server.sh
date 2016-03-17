#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="3660446622"
MD5="77854e623dec1c1f55b400227d42fbc1"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3957"
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
	echo Date of packaging: Thu Mar 17 15:25:32 CET 2016
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
� \��V�kSG���_�Yt��-�$W`qQ@&��B"NS�ew�֬v��&X���gf�H�l�W���hg�{f��3S�\��m�������l��Fm�V�i���ح5�׶j[ۻ�5�Y�-��X�l�c�b����O[u�gA�V���%�zcwg7'�z���[+������io�EY�����y���
jT���:�a�u�nKW��lm�@-n�e96:��az�!�}p/�a��=�z:6�������5q�`����k��OT�<ܠz�M ��^s3���S�7�Q���rr4�w�b��/}o�/�P\+�g��gg�O���=u;������[�_�y�W|�q�s��T��N�{z�4L�r�Eq=�Ff��2<(�����>}����5ۃb"�T��qӱ�K�Н���RQ@49}VD�?'+��Q�F���]1���$����g�-�&p��A�3Jk�pٕc>��]Ǳ���CD��a���ZB)'ۄ�-�5\9>�d��s��.wBOg�+�J��9TɁ�� �D�ܽ�|�0mO�#�L�:�cɌ���k����4;ͦnp��d1J�d�#���(���up5�g�O��V0��S�&����m��B�	����}0�hZ��%�q3^K��z4�D���gZ8���xִ6,D��	���p:����N����h��w��h��lo7�Oc�9?��^��/^��b;U
�Bƫ֗��O��R��E_a8����6��;-�k�b86F5sP\��@H��L�e���c�G��2�*��������GF��Q�:w�UUIk.Ԕ1�xl����z#W&ܻ#��_Ņl,�-ۤP�l��~���q��37��$!}v=E�;�Ϳؓ�.c�E	σ<f?�P��)�Ix�x�
7�;��1���vC�1E9�=DS��}"�T�au�Q_���f�M.��:l~�&�ec�h�O틭-���>���V�bU�o��t���2����)�ȥ>,�E,�R�C�����#M��*j;�P"�,��΁C�簮i��(���wi�P�̊C#���}��	vΊϏ��V<��Z�q������N�=<���4UE怾��Wd�(�w��&��t��<�LE�U�.4���#?�uL�Ҵ�Z�~�(:�L+�X��DL41㔩��m��vee��$�r='pt�ҒQB����ߠ�%�nJgC�if�cF����yVը� �P(�ldBr��vN:�v��y#�U/z$4HÌ-������n�[���m����?�/So�Z����
���.>��g3���C~,m�	;ӎ6)����P
t��ßO�;����[���}áB�=7z��lc@��>�"1L��@wl�	G��xY-C?�}��RE[_�i��&�sT͸�4(���j��OƗ�?�Z"�d�OJt��E�CY&Z��*�u�)�"N��� ��:�����Ǧ�(�d}*����&�É1b�rXn�δ,�'�M�g�3kL.����x��ҐvB	Pʪ	�s�c��v���j�>���� �M�G���S�]���i������G[UH=��F�Ɖ�0��Y�B��\K�)�0I��H�i�W�ڴmF"ΘwYh U��	91����.p9�灩���m$�	i�Ò���&4�V	 ��cK�=��)���p�LʹŞP��3�i�!��X)NI�.8�m��='��GlӐ��	��N�@z"��]���}�u��10Ap�����Ct*G�;�^� c2$EH���A�+�Z\TOt/�k���I����9�'��hx:���p71���n�?���΍^�O�F,L,¿�6���5�i6?a´	�+�"�.fWP�o����c�N86�ҲQ�B��EhA	{sF���2���D���o�܆Ix����g,�HBӐ�����Lb4�2�ywXh�-8S!�xN�v�*	�i�X�U-5o����P �v���4Oxg�z<5��`/b�fp/M�{���OT��
au� ��&�ۚ8a�"��#�G�)�(44Q���Sܑ݃!�&�a��9>�Ĺc�l�G��ؓ���gSM�ף�b*[��6�C���S�y�Ϭ��]<?�r~n�����ɂ�}`:d�w��7�u*��P�a��6/������݁�9��˂�QVG�\6�R1�*h��R�u1���y�H��̇(�d����b��C��"DA��.+=EUU����w<�=8�[�PY�Hh��S�d�*�,�nq�g�
��2�2����KYd�-)�UZֻd����xz3��?�����8�FiDm.a�r!��gpI�-�Őb���>x�ly	u�B���ur�m�z߱����%�`���x�����A���	�8�0�s�_�(��;��/��߆�a��T]1:�`�9���E����;09�ס�qA����uJQڇC��Z'��c�]��+3d��B0���y{�,������sS��+f���+�GU�`�nX�4�&0�.��E��q96H���	q���)����ۓj���w�=�����z����O�uqj��
V*�o�	8W7_O�s�D�z
�q��^�1D�h��������B|.���y�J\ǋ��3������*B�6���G�������Tx�BR�bu
"�X��0�f$�d^Nb�!�i���O�a83,u��\<��ɒ�?�Ǐ{@w`�:mR��Z�}�jF$�5W�?�W��r���W�p|��rW�`�`��<zJ��=�1PI�R�`/�=����U��m��=��+nT�F�������y���7U�X����V�bᆣT��4T�[zƑG�Si�?�)���e�F�W�n|��*�����)�3�TCw�&�?j�u�퓦Z�H_R1��,���NN�se+rt��qs��;!<av(q��\�,"��WH;|���[��������	G�o{��.�v��K�u�[���UB��3���4�$�9����� .��W�= �؆���H�T�rY~=H=>Q�!:mCcS�^�<Q��"i�^w���<?�_y����ߵ��e�'ln�n���G�*�I��ˁ7�q/}��|�Д�x��i-�X���_>š�9䧸�)�wrk����Z|�y��[����D�aTZ}���?mo/|�[߭�������oђ7{��U�u���2^\��e�FU.>�����y@�*��m�<�J��I�X'�z�]�躃�'�ď�a�c�XG�M��U�2￳r��Q�������]��7y���kL�a��Ɂ����a:ٮ���l�T&9�{3�)�-ҝ٠}|��a�:�w�L��ţ�󓑄�G
�ɯ�0;������l��ۋ˲�h�r��_~`"���-Ђ�>��[�#;D����ɑ��b��KR�^[t�D�L<4�{̝�x��|o�\l�olv���JƧ��J����[�����9����m�h�A�%�����h��A���
ts��n�JA�p[/�ǩ?bq儎���~h��T�,r+�!L'3����r�&�@��5� ��.r�s����!�Z�͏���0ېr�q�&�j�?v<�h&��^gT{^����$l�#coO�۰ׯA}���rc n�0��^���p8��/��p���%s�s�ǹs��N1��� t���^��D�6�r����B���%���?��Ă;�|��gN�oH?m�⭔��$ː��r�,C�7ݜ�C>�{�R�+��G<_�\��{�����4��$��*/3A�Ծr@oL�z�_�X�+�&����$!�gP�3:U�'�x��I�?����}�Q�H�2:��ջ�F'�9�E�B�&ۚ�R�U[�U[�U[�U[�U[�U[�U[�U[�U[�U[�U[������8 P  