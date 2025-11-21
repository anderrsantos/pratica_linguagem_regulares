from converterAFNEpAFN import AFNEpAFN
from converterAFNparaAFD import converter_afn_para_afd_cli
from testar_palavra import testar_palavra_cli
from converter_multi_para_afne import converter_multi_para_afne_cli
from converter_minimizar_afd import minimizar_afd_cli


def main():
    while True:
        print("\n=========================")
        print("Linguagens Regulares")
        print("=========================")

        print("0 - Converter multiestado inicial para AFN-E")
        print("1 - Converter AFN-E para AFD")
        print("2 - Converter AFN para AFD")
        print("3 - Minimizar AFD")
        print("4 - Testar palavra")
        print("5 - Sair")

        opcao = input("Escolha uma opcao: ")

        try:
            opcao_int = int(opcao)

            if opcao_int == 0:
                try:
                    converter_multi_para_afne_cli()
                except Exception as e:
                    print(f"\nOcorreu um erro durante a conversão: {e}")
            elif opcao_int == 1:
                try:
                    converterAFNEpAFD = AFNEpAFN()
                except Exception as e:
                    print(f"\nOcorreu um erro durante a conversão: {e}")
            elif opcao_int == 2:
                try:
                    converter_afn_para_afd_cli()
                except Exception as e:
                    print(f"\nOcorreu um erro durante a conversão AFN→AFD: {e}")
            elif opcao_int == 3:
                try:
                    minimizar_afd_cli()
                except Exception as e:
                    print(f"\nOcorreu um erro ao minimizar AFD: {e}")
            elif opcao_int == 4:
                try:
                    testar_palavra_cli()
                except Exception as e:
                    print(f"\nOcorreu um erro ao testar palavra: {e}")
            elif opcao_int == 5:
                print("\nEncerrando o programa. Até logo!")
                break
            else:
                print("\nOpção inválida! Por favor, escolha um número de 0 a 5.")

        except ValueError:
            print("\nEntrada inválida! Por favor, digite apenas o número da opção.")


if __name__ == "__main__":
    main()