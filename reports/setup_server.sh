#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="1158384765"
MD5="172f59d2ce69a312f937174398fe3e14"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="3964"
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
	echo Date of packaging: Thu Mar 17 15:32:12 CET 2016
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
� ��V�ksGR_�_�Yq�	$�W�хHX��%P������A�����C����랙}
��؉������t����g檛k_�ma{��Kk�w����V��𺾻������Vmkwk{v�������i��1m1�S������ t����}g�^�ɿ^ߪ���J�_���92�M�(���� ��9���f@�)J���t�'�F�4�|fkSjqK-˱�Q���K)��u� ͳ��`��i�(>�����k���Y�wz�����?QY�p���i'�{��`�nN�t�#���Q��9�u>��8��M�Bq�Пx���q>q�J�h�i�t�<�}�k~�Z�h����D���(G�f���a���\)��z�'�rKexPt-�7o�u�V9��+��D*P�����c��p�;�)j륢�hr(���N>V*4Q�v��&��-�bh�I	4��ϼ�M���A�3Jk�pٕc>��]Ǳ���CD��a���ZB)'ۄ��5��I��Ĺ_�L�;��3��D%������S�i�K��g������L�Ɠ��)Ӿ���X2��B~F�?�n1��B��ܣ,Y�1����{�4
�c}\���S�~�����ۉi1��@����h@e./a'�tt	b܌��D�E-��� ���?�5���s@�-#�(��ao���=:}7���jlo����lן�<j�t~����=�_�҉9�4�v�
��W�/��4O����a8����6���5]1��9�(�C�
���h&��2}�ڶu�#[IE�Q߅R���Ѐ�#���(S��ڪ��5j�}<�qhsR�����lzM���B6�͖�mR�X6�|?R�]���sf��>�������IX�1ɢ�����E(m��$�Z�@��g�\�T�&w�����i���)��>�X�]3�:�/^�㠟��P�LPȫR[��/��l��}������'5��hV���͓�vo��WrL�3�h����U�}�� �]8x���[E��Jd����9ph�5� �3���$m��YqhsV���^1��Y����ъg_U�0T3#�{�����G����ۆ��4�Wb�,��hۀ��Nk�S���Hɪ��ƴ{臺��W�4�k�Aǚi�˃����&&�2���Ԣ��FV�N2.�sG�D.%�8�:�5Z\����1ĭf9f��뮟gU�Ju�cQE;�F&$ ��N��=h%,p�7���b�G�@�4��Ү�,�/�V��i�ڂ��Q�����7~w��Ņ!^�v���:�)@�ci�Nؙv�9H�4\��R�C.�|��y�Ŗ�b^��E����cqf;B�����L��c�L8�u��j��{���*��M7��j�fJ	�U�g~2�L�	�I&k}R��.��2ђ��TѮ�LQq��E����a@շ�W�=6u0�I$�S��-8g0'L���W�r���e�>�lJQ�Ycr��	5ŋ՗��bH��ZM�8�3�K$�4�T�	��<lJu:��4��c�B�$p�k���5�>bتB�y��7�5N����h�
T��=���S��a�����G�ʴmF"ΘwYh U��	91����.p9�������m$�	i�ݒ���&4�V	 ��c�K�=��)���p�LʹŞP��3�i�!��X)NI�.8�m��='��GlӐ��	��N�@z"��]���}�u��10Ap�����CtpG�;��H�1�"��ET�"��d-.*�'���5�w�$�~��oπ�fo88vN����|_\�	�Ԏ�JK}�F/uէa#&����
Uj��n5�Baڄ�FY���+��7h`Wȱh'�i�(E���"����9#�ks�n�b���[��Un�$<Y��cD$�iHq�����&1�o�[�E����v<'i��5K����4i,��ખ�7VJ�q(D;�|q�'��3E=��HX��qF3��&˽��}����xL����i�WA��mM�0@�����#�w���UQ�)����{������`�ܲ�E6�#�~�I���t��&����`1��Ƿѹ�ܣ�l�7�l��%����g�ϭ��QV?YS�;�C�z_�Q}�X�B�}q*:l�����e�t��T��^P3""yYP4���!����UJ"fW�^*�.�Q:��Ғ�E�L^�-�P�<�Q�Btѱ��ST�Q�8�x��؃�������A��:�K�rˢ�g�q���!)�*���x���E��=ђ�_�e�O�������7��i�3Ol���G\:���%�T.�X8�.��%��R,ѕU4T�o��-/�.U�OQ�Z� ��V����	/Z"A
�x��ʑ)K�g�@�p�CC8�������ߠQ��<�e�tZ���&�^M�PD{*�����yz����]��u8�^�y���<�Uh�2C�)s���윷��b�� �˯8�K1��0UQ���i�u`��=ċ���r������1V}SP��}>"�'�27��q{Pۅ�-��Y�a������
j1�T(`��p�n���ʉ�����D?xQ��b��8n�(�K����[p]��{GP�:^|<�a���^���������<�|X�f�0Ǧ�����;�S�ƒ����Cy� �r3��M��~�Ùa������NoL����>~��&C�i�*-��;�T3"a��*���rF���������8}̐�2�����SO�A��Jr�2{�ѷ?�2|k{M�a�^q�J�?��~m��λ�v���*�R����7�"t`�����K�8�J���QN�M�,K7J��t��s�FW	'�v7�H�E������51�Q��=h�4�JE���I5e���wr:�+[��k�=������١�A�r���^!����n�+:��/d�S����%\���^��h��.�֕n��W	���<h��0��_���G2ヸD�^�/��c���@\Y��Ő��#�~�}�ڏ��i���b��U��O�'I�-��.��I�D,��o�:�/�,+=as��w���X�?NU!Oj �\�Q�{�_�����#}Nk1��J��8n��)��!?�����[[�w���Ï{u��ڪ����vͨn�����Y�������[��^���+Z�`e/�ޥ���R�Q&�д�ܨJ�Ň��~�A�ϖ~�J;�B^�@����,T��?}����n�.�c`���X<֖`ӕ��R�����`�۵����oo�^��_��?2�7X�8���%���t�]�9eٞ�Lrh��f.Sֱ��~�������y�����b�G��'C	��/P��7b�A?0��_��Z���7�e�A)А�8�!���,u_)�+8��e�0���eB�P�D@���W]�J�ڢ{7�d�i��caT(�ǣ�;���0�����2#%��O}��+P��wjy?��u��6�� "T9��zK���ǭ����q���&�]�����^J�S4����	M!`���Y��Y�VfCX+d6�!�c����Cw�(��i�%_��s�H�RhQ7?ߧ�W�lC�9�=�D�Q��񸢙�
�y�QI�y���W��Q���=��:߼�r�jɾ��Ò
{M�����־���)R����A����m;��b��`�ŇKz�&��$˩rn
Q�˗�{F�HN�W�l��9��%Y��S��R����,C�k����9�|ts:��.�K�B��|9rM���"�W�]�P%!�Wy�	����zc,�c�2ĺ_A4�@�F�%	�?��"�ё�>)�K�L�u�3~�/؝�jDJ��a��N4:�Ω-��Xz6��l���ڪ�ڪ�ڪ�ڪ�ڪ�ڪ�ڪ�ڪ�ڪ�ڪ}���z38 P  