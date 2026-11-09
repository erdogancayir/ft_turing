NAME      = ft_turing
NAME_BYTE = ft_turing.byte

SRC_DIR = src
SOURCES = types.ml tape.ml parser.ml machine.ml main.ml
SRCS    = $(addprefix $(SRC_DIR)/, $(SOURCES))

PACKAGES = yojson
OCAMLFIND = ocamlfind
FLAGS     = -package $(PACKAGES) -I $(SRC_DIR)

all: deps $(NAME) $(NAME_BYTE)

# Native executable (ocamlopt)
$(NAME): $(SRCS)
	$(OCAMLFIND) ocamlopt $(FLAGS) -linkpkg $(SRCS) -o $(NAME)

# Bytecode executable (ocamlc)
$(NAME_BYTE): $(SRCS)
	$(OCAMLFIND) ocamlc $(FLAGS) -linkpkg $(SRCS) -o $(NAME_BYTE)

# Detect missing tools / libraries and install them with opam
deps:
	@command -v opam > /dev/null 2>&1 || { echo "opam is required: https://opam.ocaml.org/doc/Install.html"; exit 1; }
	@command -v ocamlfind > /dev/null 2>&1 || { echo "Installing ocamlfind..."; opam install -y ocamlfind; }
	@$(OCAMLFIND) query yojson > /dev/null 2>&1 || { echo "Installing yojson..."; opam install -y yojson; }

clean:
	rm -f $(SRC_DIR)/*.cm[iox] $(SRC_DIR)/*.o

fclean: clean
	rm -f $(NAME) $(NAME_BYTE)

re: fclean all

.PHONY: all deps clean fclean re
