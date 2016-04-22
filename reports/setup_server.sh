#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2796281525"
MD5="0385a6d9d7e1c9d071e5972d93d8610a"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4055"
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
	echo Date of packaging: Fri Apr 22 17:05:19 CEST 2016
	echo Built with Makeself version 2.2.0 on linux-gnu
	echo Build command was: "/bin/sh \\
    \"--header\" \\
    \"../../../MDSip-tests/reports/setup_server/makeself-header.sh\" \\
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
� �=W�ksG�_�_�Y8�	$�W�хHء!J�89YE�v�ѾnzD�_���S���JruL],v��g��=3��|��m���]��|�������ۭ7;�o��}�����j���@��P�^h��3m9�S������0���ϒk�͛��[����Z���[���K��f�Rvg��:�|��5�LQF����x�9�+�K-`�f3P+[jM�M�z�8f�~fHaw��0�~�'ߟ����C�k�m��f�� ���'�`��k���7���S@����mo�6ӛ���+�G�a�l$����B�(�7�Bų�`N�ap��ĉ�k�M���N;�?M����Ex˼ܫ<�� �B��0���|h�f�W��x�鄓��j]��;螼W���A%���p�z��:���m��^(
�&��Ϻh����z�&�AܮP u���Ch�N
MJ0������p� 
�U�M��
�$k	� i��Z���(���ϰ�	��B-�T�tJ���.݀I��̽�@�M����3���%Ǌ���o��k�K�>`A�����L��Ɠ��)ӹ���X:��AqF�Z<�n1��C3��Q�,A���t��B��R.����6��t��`O�����s��
�6�7����p�iAG!��d-IK���P�R]_
B~j�����Y�ڰ��;$�R0r��'{�����Q����������v�ị�wgr���G��W:3�_ƀ�N�R���ճ@���~�/1�^�T��O�����1Μ�9T�P�Bh�4�I��L�������V2Fр3�w��0u}4`�Ȩ��T箶�*Yͅ�2E�m9�To�i�{w�����=�G����M
�����G� ��	�>s{�L2`W6z�I`���3�,J��<��g�Ӡ��OA͢��T���f�8 Lɕ��5�[t��L�La&��R�	�	G}�rA�/zhl�(�U��a��5A-FD��Ծ��2�M듚�n4+�v��gL����OPA�e*���0��^<0W�"�K�6��󜦓K���*�"QhP�@}H�	�6Д��}�u.��z�A
!@��K�gy���Z��[d�ϵ7$�`����{#�{;;/ܛ�Ml�<��z�ɨ{�C�trz6�檰��L&����?�.~�������}[Ud"(I�@M�{�Q>І��~w�ۗ�H2$�\gD���a�`0�A��iE>+�����&��2�ֽ̢3�.���愞��f:J�Ij�����M���O n53,0#C^��"��t���6�x�9Ȅ�l����ݔ*�,�=� ea��v�a���;��]�u����/Ƌ���aR�Q��hW��d�J����X�7��̆��T.BC)IK��,&ʝ�Bl�ke!TB�����=wX>:.F�ȣ}�Eb��E��:���xy-C/�}��JE+�д�����f\a.�B,P�{���B��d��'%Z�r�PV��bė��sEU�	?��+Ø�dF���3��<+�l@U<?d���y<�"Fl^��-ޚ��aDs(�fMɅ��j�</և�N�!ʻ5��p��w-��oд��3���. �M'	H��tJ߱����a5 X��_�\�H`
��kS6�au}I��nE*��=x��S:�a�������/ٕ)�a�)�� �qbs��]�r4*2BS�,���H:�0�X>S~�Ô�* ?u��I���ks��!����LG�	%�9C���+������d��9J��pB�z�6�O� }�m��	$�$M ���������O��F�8�}I�LȐ1| -��A�� kqQa2ѽ��Y��'!�kv��w���ɤr��������MP�v��S2X�;7z���0���>�-T�7�k��~L���WEl\(2̩��ߠ�]!��pl����#�ЂR�����c����7;���7���d�d����!E��nMb4�2f�����-���v2'i��UU����4i"�.��켉R��K� ޹�#I�-\��6��`/b�fx/M�{���O�Tӱ锪yu� ��&�ۚ�Q�"��#�G�)�(44Q���Sܑ݃!�&�a��>�̽e7l��|��'=���۶��Ǘ�S�J&�OnkV�A��ՇЋ�ŗS籟:B����><�ܓ��86x�̀�1�اJ�j�O�a�*�P�a��/��ne��e��;��ϒ�8��2��|Q�&"~C���e��r<�X�"���Wy�k����ʓ�TˋŲ�1����W/�R8.��';�x�|p����Z8�2!i^\?Ou]�'� ɠ?�$����2�OWkr�4��\q���?��]}�����`4>��Ӳ?���~�F{�(�s!R8��L�):V�t]����s�5��׽3HM��3̟I���ng�"����J�� �I��0�Q�n��4�0I�4ɰ��X��Y����]��_�޸�m�����	g�]ͼHd$�a$��_S�*�5.�x�^�$�{8�a�s<�r*���D'e!�'�&p����uG�J�� at���uK�d�+�Č[E	��"�RӯC3��.�!Y�<�c��U���O����A����ܞ<2�ݲ��Asv�0�����T^�7�YR+���B	�����su�,8WN�oe�^"���F×�5���v��?��`I�Y����u�� x:�|X����?��_�4���S�'0[�����T$E�WQ �ƒ��@Db�Q*D��I~g��.x���;�)Y2��Sr}@W��>R�E��@&T#a�*����rNwм�ܦ���L_�ݎ�J�����}$PP�3�00���I��ޯ��f��h�t�(�h�J�/��>��Y���Ѥ�*tC�nr�h�*mA��G-C����t�/O7���*��q�7(�-Rxn�Zh�M1�Q���7���z]���I�s��.vv:��[����}��K<�1�1s"�����1,#��'e�ݘWt�'_+�g1�g�8?:�8�x}�uB�_PU/�#->h:��{jFEp�.8/h��x��P>�K�n��BO��v[|���1o�\�� �e�
�������1�����/|�Q�mOn��]�~�{��_�G9b��b��O#��j�*V�Ew�i��u�C1Q���`�����������Ԕ����Y-�X)_?աR?������_��������^kΓh���=֮Uz���������߭������Ns����h�������yJ�[r.#�2
�*W�q�w�+�B�Wx� /G���6�ֱ�\���'8����]���0���d�'�l�ź}����O���������k��C���&��hWccv���Ah�n�+4m�ﱵpV@�6�p	�RƄ�.G���&a��a�;�Z2<8;�H�ҡ��3\��Y�������9��)J��,���U&C�JI�i��n��-�?�Cp������I�$��uD�n����п���TB�G���=�a�ҿmp�-�F�*Y����נ���~{�"S7��D�~��V���>t'[���z�>��Y�"�eT&��Q�R�d`�ҭ��R�&	jܙT�X��?��ZJGG[�0�Vm�&r+�0Lys˰)ϓ �	'���Z.��)t.V����|�W�F�X%�)�Aq7?����C*]<�5��9<u}��&�����{^���ݤy���ޞN��ށ��B��H\�a��&���prk_`��;H��Y��3�]�.v����%���/�1�kLn�̸��Y*ŝ�^��9�#9Q\A"�#z,��W���=���N5�Jm:N�
Y�a!*��*�Dp��M{�)]QW�]q�?��
�:���sE��f�š�B��2I����Y�Ǳ�kw�#V��i_����RwU>��� �{N�F��������x�/ٝ�:E�Sh�n��4:�-�0��Y��|�%�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ���o�/���� P  