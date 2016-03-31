#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2585954505"
MD5="9d0b4939e2245158e3a1085a637d7263"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4017"
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
	echo Date of packaging: Thu Mar 31 14:09:21 CEST 2016
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
� q�V�kSG�_������$l	$�������*$��0�ZvGh;n`B�߯{f��$��$�*M]�v���g�=3��|��m���]��|�����g�֫ׯ[���泭�����3�}��(5���>Ӗ�=6���#���.��v^�*ʿ�B���������ۼ4��`�(e`��\��~��f@�)���7:��v�z���ljeK�ɱ�Q����)���!�;���ɏ'�q�r���k[��Y37����i�����Be)�''���7C�۴���&!#����h�?	>�3_�&g�P<+
����|�8ј��Ѥ���s��d��X���˽�}(Y �.�
SQ�z��ɻ�aj�{�(��N8�1˫��^ѵ޼���[�,Ю�TRA����\����6��hr(����|�~��i���
� ��P��J�=���Ф4�o�|�����P5�T���K����F๮U�Ѡ@�"
A����-�RJI�Do�(�p�L�f�-�ozH܍|�ɯ'�+w��C���rMt��,p�c�O��B�Qp�)ӹ���X:��AqF�Z<�n1��C3��P�,A�7���w
iZK���t۠_h�!�=�vfZ���*��P߀��Í��7^���׃��������������f�a)"ww.H��`�&�:N��G'�'�������ݝ����G����pC?b��s:3�_���*�R)�c[�g���S��A�/1�^�T�?O�����1Μ�9T�P�Bh�4�I��L�������V2Fр3�w��0u}4`�Ȩ��T箶�*Yͅ�2E�m9�To�i�{w�����=�G����M
�����G� ��	�>s{�L2`W6z�I`����3�,J��<��g���ُA͢��*� o}3d���l��-:b�r�z��0��D�R�	�	G}�|A�/zhl�(�U��a��5A-FD��Ծo�&��f��J���ӯ'��	*��ҠL���wF�C݋�*\$v�Ӧ�p��tri�cc��B^�B]$
�7�I��3���<Wb��|�.�C�8�g���@�!���xf�������EF�TkC�x���^�.X���x��nb��u�MF�ӟ���ӳ��7x7W�e<�]`2���u��v�Ko�MOo۪"�@�Ob
h�y�6�����ܾ̀E�ؐq ��:� �u���� �a�:�L+�Y��D�hb�,�m��0m��vi�М4'�|7tuL5�QBORW�F��.�-=~q��aa32�u/(nU��0��=�57!9�{ǽq7��V�ˁ�F ��0SK�
�0?u��N��s'G�~�W�����ig��fT&�ڕ�34��R�!�8���vfCAR*�����b��Nr!��5��*!�PDR뎻,�T��:�"1��"Gw��PQF����¾{�o���WhZdx��U3�0�K!����U�O�VH2��Q���\��U���-�\Qq@�qF���0���Q�1��v1�J%P�Y��`�<�I#6���oM��0�9�D�����]^�j��Ci�Đ �ݚpq8g軖H�7hZ[���|̦���k:��؅��H� ���/j.}$����е)Ɖ����D_�"��<K�)��0�L�HӉ�Kve�xXwʻ,4���F�����xȎFEFhꑥ�YI�AB&�g��s���K% �O�pR���zj�A�q�fj�#ք��;C���+������d��9J��pB�z�mn?y���JO@$��G�4q�{����� �@��0|�!:h$�ٗ$ȄI��"*oD�
n-2&�I���|B�fw��o�qg8�L�'��>��L�.��Ej�O:�K}�F/u5�a#LwA�l�J�)��Vs�1�K���(bk�B�pÜ:����X��������Pb�"��t{F�y�n"3�bG����a��\��A"��4�h{���֤��K�,�3W���N�$mױ�j����4M�Ȃ��|1;o����R �W��HRx�F=�M$,��qF3��&˽�\}�B���tJռ��i�WA��e��(D�����a�;
M��(�wdw`��IzX�aa`�޲�E6�w��ēM��m[M����)e%��'�5+Ϡ���C����K���؏!|���g|���g<zf�>1�؇J�j��a*�P�a��/��ne��e��;��ϒ�8��2��|Q�&"~C���e��r<�X�"���Wy�k��O�!�Gϩ��eYcƧ��^�p\6/Ov>����`a}E�p*�eBҼ�~��,O�MA�A�yI0#eUe�]���&�I��~rű�J�HW�����<�	�h|2���e�ə+.�&$��
Q(�B�p$�*\St�T�0��o�`k���{+f����g�?�����"����J��?0@�&iN�F��9g8���$��$�z�c�wg=�����O�޸�m�����	g�]ͼHd$�a$��_S�*�5.�x�^�$�{8�a�s<�r*���D'e��O(M�����?�ڕj�^��Rw��v�,�Wt���,�Eإ�_�fh�]�}��<�c��U���O����A�����\�<2�ݲ��Asv�0�����T^�7�YR+���B	�����su�,8WN�oe��#���F���5���v���?��`I�Y����u�r/�t���v{��痿Pi��Y+"ʧ�`��ϩH�6֯0�@č%5����̣T&�����+]�>w|S�d������*�}:�
D�3�L�*F�XU��+���y?�M	��	���r���<
�	��H��*g�a`Q9�X=�^���fױh�t� �h�J��[H���,Nk�hRC��W79p4B�� �񣖡[H]S�qƗ��_@W������)�7s-�Ц����v�w��j�.}Jݤ��T;;�NЭ��u?}��K<�1�1s"���%������2�n�+:擯�䳘�����\�<�:!�/����N�垚Q����})��$�"����_�	��n����>�M�̐�
b�Q歐:��k�y�iy	\��Ge��d�x�e�I�%�#���٫ɪTX�>�)�1���D˓���oԒ^��/�SS.�>g��{b�HL\,|�T�J���W��_��:_;Zk����֜'����{�]3�����﫝���[�����������_��'*{�.����2�\F�eFU�����*o(*W��z��0A^�@���m,ԭc#8����'8����]���0���d�'�l�ٺ}����o�����N�����w�������M��Ѯ0���@I���0�|Wh�,�ckᬀvl�0��	']0��L�:��~w�9�dtpv<�#��C1��&����%����}s~QS�Y���"̅�����b�.��%�?�Co�����fI�$��uD�n����п���TB�G�w��=ra�ҿmp�-�F�*���͗�����~{��n8�o�P�@3꭪?���N�_��:}�n`Z�U�AK)	n���8���0WK��h
!FV���?DN`��inA�7�\,-7P8t�,����\pF܈���b�B����4���R�� �!�$R�������T�ϛ�Jbϋ�����zd���tu����q��b��/Lܱפ8Nn�,�N�Q�t�b�8wa��)�������Sh"1�M����R)�|����E����)�Y��[�ū�j���"t�d��a!*��*�Dp��M{�)]
W�Uq�?��
�:���qE�r���PU!��E�	����zU,�c1��O(����wUB<��!���t8�Ϫ	��Iu?����}�Q�H�r:�ݍۙF���E�>#�!ۚ�S�u[�u[�u[�u[�u[�u[�u[�u[�u[�u[�o���- P  