class AFNEpAFD:
    def __init__(self):
        self.tela_inicial()
    
    def tela_inicial(self):
        print("\n=========================")
        print("Tela inicial do conversor ADNEp para AFD")
        print("=========================\n")
        print("Informe o alfabeto utilizado: ex: a,b")
        alfabeto = input("Alfabeto: ").split(',')
        print("Informe os estados do ADNEp: ex: q0,q1,q2")
        estados = input("Estados: ").split(',')
        print("Informe o estado inicial: ex: q0,q1")
        estado_inicial = input("Estado inicial: ")
        print("Informe os estados finais: ex: q1,q2")
        estados_finais = input("Estados finais: ").split(',')

        exit()