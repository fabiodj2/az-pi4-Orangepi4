# Matriz de portabilidade e lacunas

| Camada | Evidência upstream | Adaptação/teste Orange Pi | Bloqueio |
|---|---|---|---|
| Código | Fork contém apenas README e `setup-az.sh`; `xsploit/az-starter` commit `9a2108a` fornece `az.py` e shims sob MIT/terceiros | Clonar em `upstream/`, auditar dependências e ABI | Inputs de firmware ainda necessários |
| Firmware | README pede AZ 1.30 e `az-key.conf` | Validar formato, extrair em cópia isolada conforme código real | Materiais não incluídos |
| Cabinet | README requer ext4 descriptografado; LUKS do UPD é outra chave | Identificar `file`; montar somente leitura se legitimamente disponível | Identidade de unidade |
| ABI | README afirma ARM64 nativo; nenhum binário presente para `readelf` | Inspecionar cada ELF; loader e bibliotecas 32/64 bits | ABI desconhecida |
| Vídeo | Xephyr 1280×800 e desktop Bookworm Raspberry | Armbian Trixie X11/Xephyr ou Xvfb; validar DRM RK3399 | Código de launcher ausente |
| Áudio | README diz baseline silencioso | ALSA DDJ-400, dispositivos e mapeamento de 4 canais | DSP e ponte desconhecidos |
| Controles | README menciona `controller.py` MIDI para clique, ausente | Bridge MIDI DDJ-400 por funções; não assumir jog/FX nativos | Código e mapa ausentes |
| USB | `PIONEER/rekordbox/export.pdb` em diretório montado | Mountpoint read-only; hotplug requer reinício conforme README | Biblioteca de teste |
| GPIO | Nenhum código GPIO presente | Só implementar após localizar uso real; RK3399 difere do Pi | Escopo desconhecido |

## Auditoria do instalador upstream

`setup-az.sh` fixa `$HOME/az-starter`, procura `XDJAZv130.UPD` e `az-key.conf`, roda `python3 az.py deps`, instala `cryptsetup-bin ffmpeg xxd x11-utils`, monta cabinet com `sudo mount -o ro,loop`, copia conteúdo e chama `az.py setup/cabinet/doctor`. Não há trap para desmontar `/mnt/azcab` se uma cópia falhar; a segunda parte da documentação parece terminar em bloco de código incompleto. Não execute como script de portabilidade.

## Próxima implementação após obter o código

Criar adaptador configurável para paths, X server e ALSA; `doctor` com relatório de ABI; testes de inicialização sem acesso a cabinet; script de execução com logs e cleanup via `trap`; perfil MIDI DDJ-400. Cada mudança deve ficar em commit próprio, separada da cópia de referência.

## Fonte localizada

`https://github.com/xsploit/az-starter` no commit `9a2108a70ca8cdef08988be22add5a469d678d35` contém `az.py`, `controller.py`, `shims/`, `tools/`, testes, `LICENSE` e `PROVENANCE.md`. A documentação upstream afirma ARM64 nativo, execução silenciosa e cabinet opcional para startup limitado. Isto ainda não comprova compatibilidade Orange Pi nem áudio DJ.

## Resultado no hardware do usuário — 27/09/2026

Orange Pi 4 LTS, Armbian Debian 13, kernel 6.18.44-current-rockchip64,
ARM64 e páginas de 4096 bytes. O `xsploit/az-starter` no commit `9a2108a`
foi clonado em `upstream/` (ignorado pelo Git). `python3 az.py deps --install`
instalou `bubblewrap`, `python3-venv` e `xvfb`. `python3 az.py build`
compilou `offline-audio-paced.so`, `offline-midi.so`, `offline-usb-fixture.so`
e `sem-owner.so`; `file` identificou todos como ELF 64-bit ARM aarch64.
ALSA apresenta a DDJ-400 como card 2. Isto valida a compilação dos shims,
sem validar execução do player, áudio audível ou MIDI. O cartão ext4 tem 3,8 GB
livres; a entrada de firmware/rootfs ainda não foi identificada. Não executar
`setup` antes de obter ao menos 12 GB livres em armazenamento Linux separado.
O `sda2` é um pendrive vfat de 16 GB montado pelo projeto RX3 e não deve ser
reaproveitado para estado do AZ.
