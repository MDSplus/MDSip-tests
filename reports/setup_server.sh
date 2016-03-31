#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2039543321"
MD5="d27cea38834d3a1dc862e6ea690e8117"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4015"
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
	echo Date of packaging: Thu Mar 31 10:32:42 CEST 2016
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
� ���V�kSG�_������$l	$������:!TH���ZvGhþn`��_���I�Ip|U���Lwϣ�=s���޶���ݥ�ͷ�[ٿq{�l�y���f���z����y�|�/�B��P�^h��3m9�S������0����k�Mk���Vk��������w�W������� �}���3E����A�ۮT���9��@�l�5969��a��!�}�\?�q��Cw<��d4nW2_{m��5k�� <<9� ��^�(,E���䤟�Ͻ�fh{����$dD\9>�g#�·�G���B(�s��s~N���?��{?�vN�;����y�Wy( %+GЅX�a*�Q��?��6L�r�E�|�	'3fy�<(�»w�=y���5ۃJ������B�u�K8�]�F��TMşuђ��o�:MT��]#�Ù u���Ch�N
M�0������p� 
�U�M��
9k	� i��Z��%���ϰ�	��B-�T`qJ����܀I��̽�@�M����3����O�^ #�B��.���t��tXh<	�'e:�1�Kgt=(Έ]�'�-�9yhf{�=�%(�!3O�^!�B5)������n��9d~����L���9�vS�v�py	�`�񴠣e�f������h(n��/!�tp��YiX���n)�Ga{��������ɨ��n{{{wwgg��4�Q���9�Џ�#��+���/;�DO�R��3��ճ@���~碯Ы�|�T�?N������͜�9T�P�Bh�4�I*�L������IW2Jр3�w!�0u}T`��(��T禶�*YɅ�2E�m9�Do�i�[w�o���=Ȼ����Mr�����G� ��	�>s{�L2`�6Z�I`��=	�1f Y��y��Ϝ�AJ����E���p��͐q@��)��2�h��˙�2��Lb�H�&P'��Kx�����)
YUje��󚠖w#��~j��2�M듒�n5+�v��gL����OP@�E*\�Cu/��e��<h��99'��=6z(DU,�E�Р03���2<R�m�"�K%V��w�8\��L��A���/$��������2��Yd�ϴ3��`����;#�;;;/ܙ��k!/��z�ɨ{�S�trz6��Њ��	$��ӌ�X'~�������}[Ud(�@M�{�Q,І��~w�ɗѯ�$�\gD���a�e]0�A��iE>+���M�e��{�Ef�]Y94'�=�]��t�Г���o���nKk�@�ifX8�y��Gդzzٸ�|���!� g�~�7�G��ʴ`9�#��Qfji�A�_�����ԅ��Q�������x�&i�H~�v��Uf���{+�emCz�Y7P��B�Yh(%������D��\�-m͢��8^Ժ�&SG�Ey��H��2��]�a�M�//eh����[)h��^:�@Ԍk��R��vςt|�S��L��$G�_���*֒��R֖a���������X�T��*��lc���e��O#��L��y>/�xgZ�͡ :�5%��U󐽘jH;%�(�ք��9CߵDH�A��Z����w�l�" }_�)t�.��[
�� `�Qr�#�m($���M�0N�����(�W��Y�N���Qf�F�N��bצ��ep���Bh�/nĉ̹�w���(�M=�4?�#�<HH�0b�L�yS|���cN�=�]�COM?9?L�tĞ���d��t"4���28�,�"Yp#�@.��N]��M��'K���6Ci	����&�sA37�+0�N����=p"����!.��@ZD�=�Y���E��D���f.���o����p�N�'���a�w3���6A����<`)�\饬4,`���"�� d��ޔ��Nsx��%<_��6p�hx`N���O,�	�F}AZrQ1jPz�%�k�n�b�͎������<���""�4�h{|���Iͷ�Q�F���-���IҮcFՀ#A#>i�4�G��bv�D(}�%G�\D9RX�F9�M$,��qF3��*˭��}l�B���tJ����i�UA��m��(D�����#�7���EQ�)n���{��0���9�̽c�l�o|��%=���m[M���BY����M\B^X�'��Ћk�KJ�y���];�����V>�d�d��}b:�s��J�r��J�����6�u؂����SAi�[�.y���="�Y���R&S�/�҄�oZ��s^�'||+���,�vx�i9��d�jy�X�9f\��#ٲH��yy�s��烃��e�)c�A>���yr벬*�;�$~��JI0#AUe�]���$<G��6rE�C��_�{]]��cŁg���'��Y%�J3W\�M���P�K9 ��8S��*]�C�}��lmu)������w��v�0������Ub�8���A-V#���]���4�00�4I������ߠR��9�׸7�w�*$hh�F�3/QH u	��!�Լ�|�3B-^��)���a�9����2�:2�8Yx�
8�~��Ϻ�v�Zy�Ч�ݛ��]1�]a��"Kt�u��7�Zt���,z��˱Q�j\L��'@��ڠ^8#>"�'˄�[��4wawc���O��~�%���*��oZ)87�ʂs�D�V~��%��l�|�]S\/lW�)�������EO8�\�+�L�kw7��~�����"�|��f�0���8��hc�
#r@\YR�\�����;e|g?Ɇ�̰���s�p�7%M��p
���t5���!Q Z(�vN(FI��#m��yq%�'d�B�v��U��p�+'��#������Yx�L4��~�3����Ǣ�ҕˣТ�*�j��l�$�
s�3T��P�n�M>Ⱥ@��-x��e�f���8���ͅ���қwz���"��fa����u�Oz��q[�ץM���1W��bc�S�܊^��瘻���"3'�8HX.`��0�^(�ּ�Ҟ|�$����/��������y�	�I��4����A��_�M%��l� ٗ��=>� .��Y�-!��m�1�ż�r1d��z�y����Y4ކ�l�^���QG��<Y�%�w����oR{��׊n�?��˫�LTh�>�)�1���D�ʃ���oԒ^��-�RS,�<g��[b�HL\&������Q��^�ȍ9�;jk����n����=�n%~���������߭����������Wi�K���C���yJ�{鉮"�2
�*W�y�w�+�C�Wx� �I���D�ֱ�\��F)8����]���0���d�'�l�ź�9����_���ͭ���ooo�������U��׮P���@I���0�|Wh�,�ckᬀvl�0��q(�5������:��~w���dtpv<�#��C1�Uƽ�c�5�	��}{~YS�Y���K#������Z݃���1~���;@95�[�tI*����ؓ����Qy�����{{d�`#���;ȍTUR>�5ԛ�At?���"���3�p��6���f�[U<�Нl!�:�}t���h/�[W��R8\׫�q�ǟX\-���*�lY�69�����q���r1��@���� ����s��F�R$f�dZ������cH>ǃ��P�HMꟺ>4�S�?�r"�=�^��jb6ʑ����-�w�~ē�Df$��0��^���p8��/��p���s�*���.l;��b��8��_/�%�HLn�4��O�T�;_���s�G�Dq	���_)�Y��{�ś�j���"t�d�\�BTΗU�	����"�S��&��!~$��u|_��,]�v�CU3^y&(����q�����~�Yh}W%ģ��xN5}VM���T���x�/�'ň�('��ݸ�iT-�-��Y���|��ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ�ۺ}���|� P  