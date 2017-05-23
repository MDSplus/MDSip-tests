#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="95774549"
MD5="2acc09da02919478f88a1bef55ddfe7e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4584"
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
	echo Uncompressed size: 28 KB
	echo Compression: gzip
	echo Date of packaging: Tue May 23 10:12:14 CEST 2017
	echo Built with Makeself version 2.2.0 on linux-gnu
	echo Build command was: "/bin/sh \\
    \"--header\" \\
    \"/home/andrea/devel/rfx/tests/mdsip-tests-build/../mdsip-tests/reports/setup_server/makeself-header.sh\" \\
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
	echo OLDUSIZE=28
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
	MS_Printf "About to extract 28 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 28; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (28 KB)" >&2
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
� ��#Y�\ys�F���ħ�@\/)��HZ��lj�H��ZJb�R�<I��!	W0�����_�n�Bb%~�еk3��9���gR�y���no�6���&�����j4v߽}�j�}���}�n��{���<�%�bi.U��������������ko�mV��&��-������X�v�L����=b[����2	4�Ԩ$�z���q�]��F-ŤD.��� ot�;�<MwY�wl�#睳O���ϧ��v�1��6lU1f6�����,Ư���@Y��������~{�3�Sc�3�(2�������P��1�`��;�!X�1|6Gxo���8q�a�G�~麟��o�A���,������(� @��4]��z��駶�+�=�$�qu�ͨ�T��QR�|�@����L�>)�2"���O�-vM.U�4Aw�%�
��Ϛ��s��VÊ�$�)��7��d��@cwb4*��-u	�g�1%>��ht����%Y�x0���6�)�B@���l�B��M�SF�1�[`
mیl�̾#Luu�۾���+,�F,;B���GR$���3�t��-�ik�0R�5�"/��vH�FHZ\�jP�J���x K	��0�aѩ���kB!1_�P������������ؿG]�/��t���K���ۤ�M���{��a=Dg"����Ū�$+��.�BЧ-�|��i�I�YZ��F���0t��]F�{'G��G���t�-��޼i5ח<��t�)U�s}����3}�o "��J�R�7W�B���U�`��0��j���yQ���f[0�rI�[�fx�AP���b����&r�Rm�*aur�.��Ll��7�>���-�e)���!M�ր&���z#G�f|& �y�N���,8_����ʪ|���	t]��
^s{AM�ѩ	^z���ҵX�R؂�Ͱ�K��P@)�:�̟.i`�N�bv �Ԝi#E̓�C�����4r`�9��X3�6v�� k�w�*w�2�&F>�����*�17'���3���ߛ��\x%�1��|x/�j�\x�.���I��;4'~��=L�r�o��=5/�K�~Nu����|=��I.��j���|֙�r�:z^|3���	�f�z0ɩt�ٹ��8�YN>'g�|"v�g���ww��Q�"ܫ���=a��[~�"�+X�KoEE�/��傃�����Epۈ�Ev�	n�=��?�훵-�z��Kwz��r��UoF��#X�[ �o� ��GOu�L���?C�橥<�� ń�4�2QO�&u<|c�6 ��<�@jw�/�p_S�A^��Fq��k��k��ot܀��nq&:�YS}�5����R7�b����|a�$�!_(Ϩ���p4���=�]���N>�ea�g�MLY��l��N��G��ӓ�mY
N���(�@2#��yr��&{�.�Z�����Vp���U�2���d�;�0E7|�f1(0])U��26Rx˖J�k{�j�d,Pb�z�w��T�ҝ�{�>"'�aٮ70`BR	���]��{ǽ�.��}�8�>U�;�C��t���A����KNN����o�����@�J>�mX ds�=��خ�43i�00I_�������LPl	?�����"����PLw��k��`*���L����j[�|ʥ�\�=��Z�([����5'�_�8�����灲8��c�*Aƍ]/и�6Sf��љ���K�$;<�4�E�1�,~��\jڰ$���0���C||XJ���<t�N7����z�o7&�mm~ڮ8 d���3x��uz�m�#�m��T<uF�K]� ���w�!	��#���ci��?"l]B%=�M<���#2��>����8����O�EaT�?�S]L][Ğ�$̠N~�}�L��C�h��������&-%�)0�/�)]�ãw0�*�*�ĵM���.�x>��n�>�d��`�n��3}�a$�p��
u��-���l���p�~��[M��� �"�bc�ȘP �Ah���8B E��7�(ȈJ���\>D�
-4ʋ*z�+�y%X��>�ٮF�;����z�铻����uQ�v<Bp����]e�-0�a��y��ԛ�6�)����WEh\(
�U����=��^��RJCo�y���И���n�c��0
/8Eg� D�)��txkٝ�ͻ�;Xd�-ئ�vT'j�
�:9<�J#Y����.Yo���m�t�\a"�*��m��:0���F�{L�{������p�E'�,蠛z0y����=)_�a{�d��&jsU&+���&���:�2�@f��^d�|�ݏ<��Hĝ�r|�`+���������yzϸ:x�8��$��.�gd'ii0c)�I(c52�X
L�1�a� ���a\-;X��;΃u7�ơ��͍�������ۍ��5Hia�b�t�b-:�X�O*6@��T�b=:�X���@+9�����T`b-:�X�N%֢S!���I�����o󠓧�����6W?���3�X�N���y��=��������0���!��~6�j��kѩ`�z���a�����^>xQ�Z����ĭ����J�v�=Uǻ��yp��ovx�zp�x�*S���U�f�G��T�K2��-�
&:�j�m�aϒ�z�-��+���8ǜ_�2!Α�YG]�}�"q4���8�X� \�s���ϦM[#��#��ׇ�qo'���?w�/����?���������X�!�2������x���)n�� ���C��d���H��2���������C6.��,q���������x�-�l�P���.�H9pN�Q2r��
�����k��U�����M��5̟I���n��;"�J-&�

T��� a�s�0L_�&"5��A�D�z�`���������{��n[�sp8�̵������#52�G���>�]�Bξ������9t�:�C�m�����Z��~��/��v�R~�`v��75CS�J����=$X���cE��t��+�Q��Q~�7L�vB�hb���W֐�����W�=��#{��t�����<� ��\N̋2)A�.i�p�n�L¹r����^B�M�_����x�򿃫�����x�Y�8��u��(�tN�������'�����l��Κ�M,	�_ޠM��!ND�Xb�\0���,��D���~j&+]�{�\E�7AK�>q����rp���!# ct���_��i OG�@xy,�_P�N�2��|*H�#B�JPS&f1+'V��L�c��X�_�6�d�і�r%lnf����e�jP�[|8��������j�of��W|i�I��r0�wz'Y��
/���k-�І����q�;���Z-�)5	冼�٩xk�^�~wy�c4�cj�A`4`21!{x%�(��#�����e�����\�~>�~}ٵ<�^c�#p��xV�����#n��QR��ˌZ_����(τ�q��G����'9h	�-����^�0�b�[S��}�p�-y�x���-q��|/#;K�PJ4�����s޼j�;&��d})�a����lY�w9x���7n2.*sR������5�o���c����˽����;�j����术�������rCq����߾y����]#����*��%���O\꭫�#�~櫱�Z&W����᯿�I�N��I����\2!��ӷѤfk�t��;t���I�ǹ�?\J��^ 3�}�O��o��V��.c�����+����~�E�-��>;��t�i��N�t��SLśe�=��,.�I[�ZŋZ����	,�:ǃ~wk2�(���x@����P�<��
R_�{dd~�^^W�f.f���+7��z/��� �-�[D���9|��p��GAN�{���RV�TK$�S�x/��x/����Ob}����6��I�Td�>�5�5^���Y��ϖ>�aP�-��M�Q�@�4L��?_|�v��<�}:���x�
]¤����;Ls*�4Xazx�M�1�DbA�w&�d)L��t��Q��<:�F+�?�N�J,�S����d�|L8;��İa����7	Ex�eF��y�m���:hP���1�5��(]�	�����r��9��!e�����G�����U����?�Xp�57�`�:��qP��^�
U$� �����ԝ�.$��E�%1@�_��;�k�n͸�G�T
_���s�'�l")��m�R�3�Qo�T��T�JVڰ�(�˪���E���_%�W�#�/î��WD��5�&GU�0^ge&8����YW�Ǻu��/n�h�kV�Z���$l�+�IzX�g���x��*Q�a�׽W)?3 /�
:��RhH���<���0�t��ڼX%TPATPATPATPATPATPATPATPATPATPA����2�i� x  