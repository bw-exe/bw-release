# BW Unlocker - Public Launcher

Este repositório contém apenas o script de inicialização automatizada e as releases públicas pré-compiladas do **BW Unlocker**.

## Como Usar

Abra o **PowerShell** no seu Windows e cole o comando abaixo:

```powershell
irm https://raw.githubusercontent.com/bw-exe/bw-release/main/run.ps1 | iex
```

### O que o launcher faz:
1. Solicita privilégios de Administrador (necessário para o driver de rede WinDivert).
2. Faz o download do executável protegido em uma área de memória/pasta temporária.
3. Valida o hash SHA-256 oficial do binário.
4. Executa o programa.
5. **Auto-limpeza:** Ao fechar o aplicativo, restaura as configurações de rede e apaga 100% dos arquivos temporários do disco.
