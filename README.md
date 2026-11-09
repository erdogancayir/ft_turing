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

### 5. makine: `utm_unary_add.json`

Girdi biçimi: `<durum>[<geçiş>,<geçiş>,...]<simüle edilen bant>`

- Durumlar tek harftir: `A`–`E`, `H` = HALT.
- Her geçiş 5 karakter: `durum okunan yeni_durum yazılan yön` (yön `L`/`R`), `_` = simüle blank.
- Simüle edilen kafa, bant üzerinde işaretli sembolle gösterilir: `1→i`, `+→p`, `=→e`, blank`→b`.

unary_add'in kodlanmış hali (A=scan_first, B=scan_second, C=check_end, D=back, E=erase_one):

```sh
./ft_turing machines/utm_unary_add.json "A[A1A1R,A+B1R,B1B1R,B=C_R,C_D_L,D_E_L,E1H_R]11+1="
# son bant: H[...]111.b   → sonuç 111
```

Çalışma döngüsü:
1. `init`: `]` sonrasındaki ilk hücreyi işaretler (kafa).
2. `fetch_state`: ilk hücredeki mevcut durumu okur (`H` ise durur).
3. `find_head_q`: sağa gidip kafa altındaki sembolü okur.
4. `cmp_state_q_s` / `cmp_read_q_s` / `skipN`: tabloda `(q, s)` ile başlayan geçişi arar; yoksa bloke olur.
5. `get_new_state`, `get_write`, `get_dir`: geçişi okur; `save_state` yeni durumu ilk hücreye yazar.
6. `apply_w_d`: kafaya gider, sembolü yazar, hareket eder, yeni kafayı işaretler; 2. adıma döner.

Durumlar `(q, s)` bilgisini isimlerinde taşıdığı için JSON büyüktür; bu yüzden makine dosyaları
`tools/gen_machines.py` ile üretilmiştir (`python3 tools/gen_machines.py`). Bu script yalnızca
JSON dosyalarını yazan bir yardımcıdır; `ft_turing` programının parçası değildir ve derlenmez.
