# Matriz de portabilidade e lacunas

| Camada | Evidência upstream | Adaptação/teste Orange Pi | Bloqueio |
|---|---|---|---|
| Código | Apenas README e `setup-az.sh` presentes no commit auditado | Obter `az.py` e shims originais, confirmar licença/revisão | Total para executar |
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
