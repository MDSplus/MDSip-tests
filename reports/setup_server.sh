#!/bin/sh
# This script was generated using Makeself 2.2.0

ORIG_UMASK=`umask`
umask 077

CRCsum="2947791638"
MD5="22f1846ad9f17f57a39b7d37f227d56d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="setup server script"
script="./setup.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir=".setup_server.tmp"
filesizes="4614"
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
	echo Date of packaging: Tue May 23 11:58:10 CEST 2017
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
� �$Y�\ySǶ���O��|%l	$�X�( ;�+@� NP��LK3۝�a�X����=;�&6Iޫ9���ק���r���zq��qo6~��M��U��h4vw[��7_�6v��5_��W��S\B^)��Re9n]��Q��0��N���*��޷v[�7{�_��B�/N[?�uk��$i���#�E���.�@3H�J���7�8�t���Xa�RLJ��\�Fǽs��t7�%��v=r�9�Խ�r6�h��_�m�Vcf3o���`��o��%����1��w<��15�;#�"s��x8�_E;�_ �����E�gs��i���g��<��~>��>t.~��}�_~ʀ� ta)O�%���}jk�b�SI�W��ьN�J�$U�ȇ�{�Q�dʔ�r,#R��+��t�b7�J�Mt�F��� +��	�>g_k5��JB��x3�LI�4v'F��0��Q��~z6S�3���F'�ox\�Ո̱m���)4
90�v)$[�O�9e$3��І��h����{�TWw���*��2��`Ĳ#T���ox$E")�=���@��ݢ��#�[�-��m�dk����U�4������Q�p��
#���:!��&�%	�,kk�8��(QM��������nPruޠ!�v�Զ��9 ��CTp&"_��Q��ϲB��b)}��̃��&5giA�m���Х
wu4}��}{��m�Z{{�޵��Kw���*�>}�_�ҙ>�7 �MK�R)叛�k!�\�Ԫ��c��o�T�]�v^�)���̇��\���iTi0�X�:��ܳT�E�JE�\���&�c���@�*w�uYJj.iH�5��oq���Q��	 fޢ��9$=�W��ല*��yD�:⾂��^PS�dtj��1�?t-֡T� m3��Rk=P��5�K� �������y(5g�HQ�����h�)��fl+�́�ˁ�n�՘��k����؉�1VY̶�U�s�"^W��?s��Os�s���|�I.����|a>��O�i.�y�OX�$_��?���z9�w���r��-��T�=~��cϞ�«���?�'a��,W�����7s�h>�0m����JG��o����sr���'bW}�I|;t����62������F��x>�[D�a�my��,��(:�E_�^pj�=�!����q�����#�-}  �s�nmKl5�}�>��)F���ouF�ۑh��HE�7G?����S�0c.��h���z�yj߁LH1a�O2'b�S�OO
��&��6-�Z���R�	+� /�A�8��5T�5�>=:��S�c6ة����R}������vy|��o?=X(Ϩ���p4���=�_���N?�ea/g�MLY�_l��N�ǣ��ӏmY
� ��$�@2#��yv,�&{�.�^��N-�A�Vp���U�2�䂧�d�;�0E7|�f1(0])NEU��26Rx˖J�k{�j�d,Pb�z�w�l��ҽ�{�>"'�aٮ70�CR	�7��]��{'��.��}�c�>U�;�C��t濺�A����KNώ����������@�J>�mX ds	�=��خ�<3i�00I_�������LPl	?�����"�᧮�HLw�#�k��`*���L���j[�|ʥ�\�=��-V����������/Pm��D���HY��J�1j� �Ʈh����)�R����x��%YQ()���"�	?`n.5mX��e*�,>>�%ACi8	�y�x|���Gط��6(�qux�̀X*�5A��k�<s�5O���P�& 31\�]E�sOH����l�4�	���.���&#BE���#�R��d�HCQq���0*����ө.��-bOx�fP'��>g�Q�1�4G��YOW}Cq������ה��(���� O�R�|��&GOt�y�LE�D�@�|d0Q�|�>�b$�p��
u��-���l���p�~��[M��� �"�bc�ȘP �Ah���8B�E��7�(ȈJ���\>D�
-4ʋ*z�+�y%X��>�ۮFN:���٨v�������uQ�v<�p����]e�-0�a��y��ԛ�6�+�E���WEh\(
�U����=��^��RJCo�y���И���n�c��0
/8�g�hD�)��txkٽ�ͻ�{Xd�-ئ�vT'j�
�:9<�J#Y����.Yo���m�t�\a"�+��m��:0���F�{L�{������p�E'�蠛z0y����=)_�a{�d��&jsU&+���&��:�2�@f�=�^d�|�ݏ<��H��r|�a+����J��@zϸ:ҿ����� ����Kv�F^�"��]V#Q���D�e&��<CH�x�����іM��<Xw3lg� ����in���9��V�"���ZdWY�T��$iaPe�l��T��S��4:JY�NR֣'9�JƩ�h/:>Y�NO֢S����T�d=z��%����<����&�/��~.���χ<�L�I֢SA���ii�$k���&�f�1�#�t`d��ͥZ���Zt*$���qX�p�zq�����=�!���.7��Aflv-��􁪉C��\�<<��w;�T=��K���)�pd��*j3�K��T�K2�����
&:���w�đԒ������\~J��ίe�����D�.�>g�8@Y�B�,a�8�em�'覭�7���Y�ⷂ������"D�!I�8���5��bX���/��
�6��lt�Q,
��Z�Jk��#�k|c�"�$c��ޮ,}[��E�/Ë���D�IQI[\��4�+D!]	�r��ܠd*��3��DfU�k��U�����M���/$ģ~�s�7"��.&�

T��� a�s�0L�X'"X6��Q�D�z�������ϝ�]�.�ݶ��I�p��k�ә�#$Fjd(��j[}�
��}l���fݣ2�wN�d+����I0�#\�p����_v��r��$��R�ok�2�0����{2H��W�Ǌz�鞁����Fϣ� o�x@"*��#��]���!�	��cSoO��{��G�va���Hߗy��A%���eR��]Ҍ�\����s�|3�o��⇯�0�nU%�����n����v�g�{�
����9�J��[�'�́��T��PkJ6�$L6|y�R4�'�8qc��r�D�b�Tbm�'�1���t�b���o���}�]�K��>-T�3BF� ���9��<�f ��0~A�v8�ˈNg�Y8� ُE*AMU��Ŭ�XX��o0!����Ǣ���gK��,�+as3˧x}.k0���
��[��P�.<|T|3Kטo��K�M������;ͺ-Tx1�,\k��6D��ݏ��E��-�j�O���(7���NŻF������ӝ�!�P�� ��	���k�T�ӧ����Ů.7�������۫��Q��0�{�Ƴ:���O��w��Hm
�2j}C�B�W�<��},�� 8ږ����8�AK�o�=L<����E8�ܚBM�[������s�$n��]�{����Y�g�����_ ��U�ݡ0������X����[��!d�����j������i\ȸ��I�nX�2�A��:�|~�@<���\M�}S-?��ߜ�����oy���R�Ӿ������-������7����?�����{�u�q��O��:�uC��ʘ]~:��9)��G�'R�e���vH���m<�';Wˎg8sE���BӃ_\J��^ 3��^����_`��V�ǌ��Z����9�#4��c��1�g�R��<M��I�n�t��x�L�G���E0i��x�m��t�=�g�d��a�e�^��Ȑ�'�t~����,�Է�jن��n�x���v��-&X�H%q݊`��b��z�,\]�;� 'ս;X��d�%��©L���G�i�J������#���&�'�����'�%��["�v?�Ճl�Su����M�Ԋ����h���ާ�N��K�%L˸�λ�4�RI�將
53N$6$�qgRI���0M�1lͣ�`���C�D�Ԁ��>5`�aJ�I�Ǆ���&�[�m���)Z�Ӯ2�|�[m�x�:ԩ@��d	����ZZ�ta&t�S�B|�'�˵^�\�Ǉ�}@ʛ7�7P�@���}��}�@�� �)�%1�3A���pTn�RA�����uu��3݅DQ���$���� {����h�Ja�7�{��#�mA$�c�Ǽ�[��(�G���w��+�Eš�U��6,,�岪p$���usQ�s�=Y�z�B�՗a�q]�+"[ښV��*Bo�2Q�k��R.P��:Q7F��-	�}+LGp6�ɕ �,=,�3@�s<!Sg��ݰ��>��p���A�B�J)4$��g
�@gtX���]m^�*���
*���
*���
*���
*���
*���
*���
*���
*���
*�������� x  