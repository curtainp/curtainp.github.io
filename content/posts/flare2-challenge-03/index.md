+++
title = "Flare2-challenge-03"
author = ["curtainp"]
date = 2023-12-09T22:27:43+08:00
lastmod = 2023-12-09T22:27:43+08:00
draft = false

[taxonomies]
tags = ["fireeye", "reverse-enginerring", "ctf", "flare"]
categories = ["Security"]

[extra]
toc = true
comment = true
+++

## 文件信息 {#文件信息}

解压密码 `flare`, 解压之后得到 elfie.exe, 同样，使用 `DIE` 查看文件信息：
{{ figure(src="./die.png") }}

且文件有一个“特殊”图标（[pyinstaller](https://github.com/pyinstaller/pyinstaller))
{{ figure(src="./icon.png") }}

`strings` 命令可以看到 pyinstaller 相关的特征字符串：
{{ figure(src="./str.png") }}

GitHub 上有一个解包的项目[pyinstxtractor](https://www.aldeid.com/wiki/Pyinstxtractor)

## 关键文件逻辑 {#关键文件逻辑}

解包之后得到 **elfie.exe_extracted** 目录，里面有文件同名的 py 文件（elfie.pyc), 此文件即是主体逻辑文件：

```python
# .... something trivival ....
O00OO00OOO0OOOO0OOOO0OO00000OOO0 += 'xDUmhGcnRDcnd4VkF5'
O00OO00OOO0OOOO0OOOO0OO00000OOO0 += 'aTBTMXd3OC8yY0ZqdzBIU0JMT0tEcktGckJUTkpvRGw2d'
O00OO00OOO0OOOO0OOOO0OO00000OOO0 += 'nNocTB'
import base64
exec(base64.b64decode(OOO0OOOOOOOO0000O000O00O0OOOO00O + O0O00OO0OO00OO00OO00O000OOO0O000 # so many variable define above)
```

可以将 `exec` 改成 `print` 得到 `base64` 解码之后的输出：

```python,linenos,hl_lines=11
class OO00O0O00OOO00OOOO0O00O0000OOOOO(getattr(QtGui, 'tidEtxeTQ'[::-1])):
    def __init__(self, OO0O0O0O0OO0OO00000OO00O0O0000O0, OO00O00O00OO00OO0OO0OO000O0O00OO, OO0OOO00O00O0OO00000OO0000OO0OOO):
        super(OO00O0O00OOO00OOOO0O00O0000OOOOO, self).__init__(OO0O0O0O0OO0OO00000OO00O0O0000O0)
        self.OO0O0O0O0OO0OO00000OO00O0O0000O0 = OO0O0O0O0OO0OO00000OO00O0O0000O0
        self.OO00O00O00OO00OO0OO0OO000O0O00OO = OO00O00O00OO00OO0OO0OO000O0O00OO
        self.OO0OOO00O00O0OO00000OO0000OO0OOO = OO0OOO00O00O0OO00000OO0000OO0OOO
        self.OOOOOOOOOO0O0OOOOO000OO000OO0O00 = False

    def O000OOOOOO0OOOO00000OO0O0O000OO0(self):
        O0O0O0000OOO000O00000OOO000OO000 = getattr(self, 'txeTnialPot'[::-1])()
        if (O0O0O0000OOO000O00000OOO000OO000 == ''.join((OO00O00OOOO00OO000O00OO0OOOO0000 for OO00O00OOOO00OO000O00OO0OOOO0000 in reversed('moc.no-eralf@OOOOY.sev0000L.eiflE')))):
                self.OO0O0O0O0OO0OO00000OO00O0O0000O0.setWindowTitle('!sseccus taerg'[::-1])
                self.OOOOOOOOOO0O0OOOOO000OO000OO0O00 = True
                self.OO0O0O0O0OO0OO00000OO00O0O0000O0.setVisible(False)
                self.OO0O0O0O0OO0OO00000OO00O0O0000O0.setVisible(True)

    def keyPressEvent(self, OO000O0O0OOOOOO0OO0OO00O0OOO00OO):
        if ((OO000O0O0OOOOOO0OO0OO00O0OOO00OO.key() == getattr(QtCore, 'tQ'[::-1]).Key_Enter) or (OO000O0O0OOOOOO0OO0OO00O0OOO00OO.key() == getattr(QtCore, 'tQ'[::-1]).Key_Return)):
            self.O000OOOOOO0OOOO00000OO0O0O000OO0()
        else:
            super(OO00O0O00OOO00OOOO0O00O0000OOOOO, self).keyPressEvent(OO000O0O0OOOOOO0OO0OO00O0OOO00OO)

    def paintEvent(self, OO000O0O0OOOOOO0OO0OO00O0OOO00OO):
        OOOOOOOOOO00O00O0OO0OO00OOO0OOO0 = getattr(self, 'tropweiv'[::-1])()
        O000OOO000O0OO00O00OO0O00O0O00O0 = getattr(QtGui, 'retniaPQ'[::-1])(OOOOOOOOOO00O00O0OO0OO00OOO0OOO0)
        if self.OOOOOOOOOO0O0OOOOO000OO000OO0O00:
            getattr(O000OOO000O0OO00O00OO0O00O0O00O0, 'pamxiPward'[::-1])(getattr(self, 'tcer'[::-1])(), self.OO0OOO00O00O0OO00000OO0000OO0OOO)
        else:
            getattr(O000OOO000O0OO00O00OO0O00O0O00O0, 'pamxiPward'[::-1])(getattr(self, 'tcer'[::-1])(), self.OO00O00O00OO00OO0OO0OO000O0O00OO)
        super(OO00O0O00OOO00OOOO0O00O0000OOOOO, self).paintEvent(OO000O0O0OOOOOO0OO0OO00O0OOO00OO)
OOO00O000O0000OO000OO0000O000000 = getattr(QtGui, 'noitacilppAQ'[::-1])(['000000000000000000000000'[::-1]])
OO0000OOOOO000000OO0OOO00OO00OOO = getattr(QtGui, 'wodniWniaMQ'[::-1])()
OO00O00O00OO00OO0OO0OO000O0O00OO = getattr(QtGui, 'pamxiPQ'[::-1])()
getattr(OO00O00O00OO00OO0OO0OO000O0O00OO, 'ataDmorFdaol'[::-1])(getattr(base64, 'edoced46b'[::-1])(OOO00O00OO0OO000OOOO00000000OOO0))
OO0OOO00O00O0OO00000OO0000OO0OOO = getattr(QtGui, 'pamxiPQ'[::-1])()
getattr(OO0OOO00O00O0OO00000OO0000OO0OOO, 'ataDmorFdaol'[::-1])(getattr(base64, 'edoced46b'[::-1])(OO0O00000OO0O0O0OOOO0OO0OOO000O0))
OO00OOOOOO0000000OOO0O000OO0O0OO = getattr(OO00O00O00OO00OO0OO0OO000O0O00OO, 'htdiw'[::-1])()
O000OO0O00O00O00O0OOOOOO00O000OO = getattr(OO00O00O00OO00OO0OO0OO000O0O00OO, 'thgieh'[::-1])()
getattr(OO0000OOOOO000000OO0OOO00OO00OOO, 'eltiTwodniWtes'[::-1])('!ereht eno dnif nac uoy !edisni kooL'[::-1])
getattr(OO0000OOOOO000000OO0OOO00OO00OOO, 'eziSdexiFtes'[::-1])(OO00OOOOOO0000000OOO0O000OO0O0OO, O000OO0O00O00O00O0OOOOOO00O000OO)
OO000O0OO0000000OO0OO0O0000O0O00 = OO00O0O00OOO00OOOO0O00O0000OOOOO(OO0000OOOOO000000OO0OOO00OO00OOO, OO00O00O00OO00OO0OO0OO000O0O00OO, OO0OOO00O00O0OO00000OO0000OO0OOO)
getattr(OO0000OOOOO000000OO0OOO00OO00OOO, 'tegdiWlartneCtes'[::-1])(OO000O0OO0000000OO0OO0O0000O0O00)
getattr(OO0000OOOOO000000OO0OOO00OO00OOO, 'wohs'[::-1])()
getattr(OOO00O000O0000OO000OO0000O000000, '_cexe'[::-1])()
```

可以看到高亮行中有一个命令类似 `flag` 的字符串，并且代码中也是 `reversed with`:

{% note(header="Important") %}
if (O0O0O0000OOO000O00000OOO000OO000 == ''.join((OO00O00OOOO00OO000O00OO0OOOO0000 for OO00O00OOOO00OO000O00OO0OOOO0000 in reversed('moc.no-eralf@OOOOY.sev0000L.eiflE')))):
{% end %}

## Solution {#solution}

```sh
echo moc.no-eralf@OOOOY.sev0000L.eiflE | rev
```

输入此 `flag` ：

{{ figure(src="./flag.png") }}
