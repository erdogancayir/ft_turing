# ft_turing

Tek bantlı, tek kafalı bir Turing makinesi simülatörü (OCaml, saf fonksiyonel).

## Derleme / Çalıştırma

```sh
make                       # eksik araç/kütüphaneyi (ocamlfind, yojson) opam ile kurar
./ft_turing --help
./ft_turing machines/unary_sub.json "111-11="
```

`make` iki çalıştırılabilir dosya üretir: `ft_turing` (ocamlopt) ve `ft_turing.byte` (ocamlc).

## Kod yapısı (`src/`)

| Dosya         | Görev |
|---------------|-------|
| `types.ml`    | Makine, geçiş ve yön tipleri |
| `tape.ml`     | Sonsuz bant: fonksiyonel *zipper* (`left` ters liste, `head`, `right`) |
| `parser.ml`   | JSON okuma + sözdizimsel/anlamsal doğrulama (`result` ve `let*` ile) |
| `machine.ml`  | Makine açıklamasının yazdırılması ve kuyruk-özyinelemeli çalıştırma |
| `main.ml`     | Argümanlar, hata mesajları |

Hiç `ref`, `mutable`, döngü veya `Hashtbl` kullanılmaz; durum her adımda yeni bir değer olarak taşınır.
Bir durumda okunan sembol için geçiş yoksa makine **blocked** olarak raporlanır (çıkış kodu 1).

Reddedilen durumlar: olmayan/okunamayan dosya, boş veya bozuk JSON, eksik/yanlış tipte alan, 1 karakterden
uzun sembol, tekrarlanan sembol/durum, alfabede olmayan blank, listede olmayan initial/finals/to_state,
`LEFT`/`RIGHT` dışı action, aynı durumda aynı `read` için birden fazla geçiş, alfabede olmayan veya
blank içeren girdi.

## Makineler (`machines/`)

| Dosya                 | Görev | Örnek girdi → bant sonucu |
|-----------------------|-------|---------------------------|
| `unary_sub.json`      | Konudaki örnek (çıkarma) | `111-11=` → `1` |
| `unary_add.json`      | Tekli toplama | `11+111=` → `11111` |
| `palindrome.json`     | `{0,1}` üzerinde palindrom | `1001` → `1001y` |
| `0n1n.json`           | 0ⁿ1ⁿ dili | `000111` → `000111y` |
| `02n.json`            | 0²ⁿ dili | `000` → `000n` |
| `utm_unary_add.json`  | unary_add'i çalıştıran evrensel makine | aşağıya bakın |

Palindrom ve 0ⁿ1ⁿ makineleri işlenen karakterleri geçici olarak işaretler (`A/B`, `X/Y`), sonunda
eski haline getirir ve sonucu en sağdaki karakterin sağına `y` / `n` olarak yazar.
Geçersiz bir girdi (ör. unary_add için `1+1`) makineyi bloke eder ve hata olarak raporlanır.

## Örnekler

Her örnek denenmiştir. Sonuç, son bant satırında `HALT`'tan hemen önce görünür.

<details>
<summary><b>unary_sub</b>: tekli çıkarma (konudaki örnek)</summary>

Girdi `a-b=` biçiminde olmalı; `a` ve `b` tekli sayılar (`111` = 3).

```sh
./ft_turing machines/unary_sub.json "111-11="   # 3 - 2 → 1
./ft_turing machines/unary_sub.json "11-11="    # 2 - 2 → (boş bant)
```

> Dikkat: `=` unutulursa ya da `b > a` ise makine hiç durmaz (konudaki makine böyle verilmiştir). Ctrl-C ile durdurun.

</details>

<details>
<summary><b>unary_add</b>: tekli toplama</summary>

Girdi `a+b=` biçiminde olmalı.

```sh
./ft_turing machines/unary_add.json "11+111="   # 2 + 3 → 11111
./ft_turing machines/unary_add.json "1+1="      # 1 + 1 → 11
```

Hatalı girdi (`=` yok), makine bloke olur:

```sh
./ft_turing machines/unary_add.json "1+1"
# Error: machine blocked: no transition from state 'scan_second' reading '.'.
```

</details>

<details>
<summary><b>palindrome</b>: <code>{0,1}</code> üzerinde palindrom mu?</summary>

Sonuç en sağdaki karakterin sağına `y` / `n` olarak yazılır.

```sh
./ft_turing machines/palindrome.json "1001"     # → 1001y
./ft_turing machines/palindrome.json "10101"    # → 10101y
./ft_turing machines/palindrome.json ""         # → y   (boş kelime palindromdur)
./ft_turing machines/palindrome.json "10"       # → 10n
./ft_turing machines/palindrome.json "1100"     # → 1100n
```

Alfabe dışı karakter:

```sh
./ft_turing machines/palindrome.json "12"
# Error: input character '2' is not in the alphabet
```

</details>

<details>
<summary><b>0n1n</b>: girdi 0ⁿ1ⁿ biçiminde mi?</summary>

Önce n tane `0`, ardından aynı sayıda `1`. Her turda bir `0` → `X`, bir `1` → `Y` işaretlenir; sonunda
bant eski haline getirilip `y` / `n` yazılır.

```sh
./ft_turing machines/0n1n.json "000111"   # → 000111y
./ft_turing machines/0n1n.json "001"      # → 001n   (0 fazla)
./ft_turing machines/0n1n.json "0101"     # → 0101n  (sıra bozuk)
./ft_turing machines/0n1n.json "10"       # → 10n    (1 ile başlıyor)
```

</details>

<details>
<summary><b>02n</b>: girdi 0²ⁿ biçiminde mi (çift sayıda 0)?</summary>

İki durumlu bir sayaç: `even` ↔ `odd`. Blank'e gelince duruma göre `y` / `n` yazar. Girdi yalnızca `0`'lardan
oluşmalı.

```sh
./ft_turing machines/02n.json "0000"   # → 0000y
./ft_turing machines/02n.json "000"    # → 000n
./ft_turing machines/02n.json "01"
# Error: input character '1' is not in the alphabet
```

</details>

<details>
<summary><b>utm_unary_add</b>: unary_add'i çalıştıran evrensel makine</summary>

#### Ne yapıyor?

Diğer makineler tek bir iş yapar. UTM'ye ise **bir makinenin tarifini + o makinenin girdisini** verirsiniz,
o da o makineymiş gibi davranır (bilgisayar + program gibi). Turing makinesi dosya açamadığı için tarif
de banda yazılır.

```
normal:  ./ft_turing  unary_add.json      "1+1="                  → 11
UTM:     ./ft_turing  utm_unary_add.json  "A[...tarif...]1+1="    → 11
```

#### Örnek

```sh
./ft_turing machines/utm_unary_add.json "A[A1A1R,A+B1R,B1B1R,B=C_R,C_D_L,D_E_L,E1H_R]1+1="
```

Bu string, `unary_add.json`'ın tek satıra sıkıştırılmış hali + girdisidir:

```
A    [A1A1R,A+B1R,B1B1R,B=C_R,C_D_L,D_E_L,E1H_R]    1+1=
↑    └────────────────── program ─────────────────┘   └┬─┘
başlangıç durumu                                     girdi
```

**Durumlar** tek harfe kısaltılır:

| Harf | unary_add durumu |
|------|------------------|
| `A`  | scan_first       |
| `B`  | scan_second      |
| `C`  | check_end        |
| `D`  | back             |
| `E`  | erase_one        |
| `H`  | HALT             |

**Her geçiş 5 karakterdir**: `durum okunan yeni_durum yazılan yön` (`_` = blank)

```
A 1 A 1 R
│ │ │ │ └─ RIGHT'a git
│ │ │ └─── 1 yaz
│ │ └───── A durumuna geç
│ └─────── 1 okursan
└───────── A durumundayken
```

| Kısa    | unary_add'deki karşılığı                    |
|---------|---------------------------------------------|
| `A1A1R` | `(scan_first, 1) -> (scan_first, 1, RIGHT)`  |
| `A+B1R` | `(scan_first, +) -> (scan_second, 1, RIGHT)` |
| `B1B1R` | `(scan_second, 1) -> (scan_second, 1, RIGHT)`|
| `B=C_R` | `(scan_second, =) -> (check_end, ., RIGHT)`  |
| `C_D_L` | `(check_end, .) -> (back, ., LEFT)`          |
| `D_E_L` | `(back, .) -> (erase_one, ., LEFT)`          |
| `E1H_R` | `(erase_one, 1) -> (HALT, ., RIGHT)`         |

**Sonucu okumak**: son bant satırında `]` sonrasına bakın.

```
[H[A1A1R,...,E1H_R]11.b.] (HALT)
 │                 └┬┘
 │                 sonuç: 11  (1 + 1 = 2)
 H = simüle edilen makine HALT'a ulaştı
```

Sondaki `.b.` önemsizdir: `b`, simüle edilen kafanın kaldığı blank hücredir. Simüle edilen kafa bantta
işaretli sembolle tutulur: `1→i`, `+→p`, `=→e`, blank`→b`.

Başka bir toplama denemek için **yalnızca sondaki girdiyi** değiştirin (`111+11=` → `11111`). Aynı hesap
doğrudan unary_add ile 7, UTM üzerinden ~1700 adım sürer: her simüle adım için bant boyunca gidip gelinir.

#### Kurallar

- Durumlar: `A B C D E`, `H` = HALT. Semboller: `1 + = _`. Yönler: `L R`.
- Geçişler `[` `]` içinde, virgülle ayrılır, **boşluk yok**, her biri **tam 5 karakter**.
- Bir `(durum, sembol)` için geçiş yoksa UTM de bloke olur (simüle edilen makinenin bloke olması).

#### Çalışma döngüsü


1. `init`: `]` sonrasındaki ilk hücreyi işaretler (kafa).
2. `fetch_state`: ilk hücredeki mevcut durumu okur (`H` ise durur).
3. `find_head_q`: sağa gidip kafa altındaki sembolü okur.
4. `cmp_state_q_s` / `cmp_read_q_s` / `skipN`: tabloda `(q, s)` ile başlayan geçişi arar; yoksa bloke olur.
5. `get_new_state`, `get_write`, `get_dir`: geçişi okur; `save_state` yeni durumu ilk hücreye yazar.
6. `apply_w_d`: kafaya gider, sembolü yazar, hareket eder, yeni kafayı işaretler; 2. adıma döner.

</details>

Durumlar `(q, s)` bilgisini isimlerinde taşıdığı için JSON büyüktür; bu yüzden makine dosyaları
`tools/gen_machines.py` ile üretilmiştir (`python3 tools/gen_machines.py`). Bu script yalnızca
JSON dosyalarını yazan bir yardımcıdır; `ft_turing` programının parçası değildir ve derlenmez.
