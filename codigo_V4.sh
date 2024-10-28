#!/bin/bash

#Autor: Guillermo López de Arechavaleta
#Descripción: Programa para la practica de control de Sistemas Operativos, que se encarga de buscar los .sh de todos los subdirectorios y ponerlo referencias
#Fecha: 19 mayo 2024
#Versión 4.0

#Se guardan como una array las rutas de los .sh
mapfile -t rutash <<< "$(find ./ -iname "*.sh" -not -path "./$(basename "$0")" 2>/dev/null)"
mapfile -t nomsh <<< "$(echo "$(find ./ -iname "*.sh" -not -path "./$(basename "$0")" 2>/dev/null)" | rev | cut -f1 -d"/" | cut -f2 -d"." | rev | awk '{print $0 ".txt"}')"
mapfile -t rutalg <<< "$(echo "$(find ./ -iname "*.sh" -not -path "./$(basename "$0")" 2>/dev/null)" | rev | cut -f2- -d "/" | rev)"

# Array de idiomas
todos_id=()
# Array de identificadores de idiomas
cod_idiomas=()

#En esta función muestra un menu para elegir el idioma
function eleccion() {
	for ((i = 0; i < ${#todos_id[@]}; i++)); do
		echo "$((i+1)). ${todos_id[i]}"
	done
	read -p "Seleccione un idioma: " seleccion
	case $seleccion in
		[1-${#todos_id[@]}])
			IDidioma="${cod_idiomas[$((seleccion-1))]}"
			export IDidioma
      ;;
    *)
			echo "Opción no válida."
			eleccion
			;;
	esac
}

#Esta función crea las referencias en los archivos .txt de cada idioma
function referenciar() {
    for ((i = 0; i < "${#rutash[@]}"; i++)); do
	echo -e "\n\nEstamos tratando el archivo --"${rutash[i]}"--"
        for idioma in "${cod_idiomas[@]}"; do
            rm "${rutalg[i]}/${idioma}_${nomsh[i]}" 2>/dev/null
            echo -e "\n-Referenciando el archivo .txt en "$idioma
            while IFS= read -r linea; do
                if [[ "$linea" =~ .*#[[:upper:]][[:upper:]]- ]]; then
                    if [ "$idioma" = "$IDidioma" ]; then
                        comentario=$(echo "$linea" | grep -o '#[[:upper:]][[:upper:]]-.*')
                        echo "$comentario" >> "${rutalg[i]}/${idioma}_${nomsh[i]}"
                        contador=$(echo "$linea" | grep -o '#[[:upper:]][[:upper:]]-.*' | cut -d '-' -f 2)
                    else
                        contador=$(echo "$linea" | grep -o '#[[:upper:]][[:upper:]]-.*' | cut -d '-' -f 2)
                        echo "#$idioma-$contador-" >> "${rutalg[i]}/${idioma}_${nomsh[i]}"
                    fi
                fi
            done < "${rutash[i]}"
            echo -e "-Se han generado "$contador" referencias.\n"
        done
    done
}

#Función de cambiar de idiomas en los scripts .sh
function CambId() {
    for archivo in "${rutash[@]}"; do
        modified_content=""
        while IFS= read -r linea; do
            if [[ "$linea" =~ .*#[[:upper:]][[:upper:]]-.* ]]; then
                numero=$(echo "$linea" | cut -d '-' -f2)
                coment=$(echo "$linea" | cut -d '#' -f1)
                nueva_linea=$(grep ".*#$IDidioma-$numero-" "${archivo%/*}/${IDidioma}_$(basename "${archivo%.sh}.txt")" 2>/dev/null | cut -d '-' -f3-)
                modified_content+="$coment#$IDidioma-$numero-$nueva_linea"$'\n'
            else
                modified_content+="${linea}"$'\n'
            fi
        done < "$archivo"

        echo -n "$modified_content" > "$archivo"
    done
}

# Función para agregar la referencia de idioma en los scripts .sh
function idioma() {
    for ((i = 0; i < "${#rutash[@]}"; i++)); do
        perl -i -pe '
            BEGIN {
                $ci = $ENV{IDidioma};
                $num = 10;
            }
            if (/^#/) {
                if (!/^#!|##/) {
                    s/^#/#$ci-$num-/;
                    $num += 10;
                }
            } elsif (/#/) {
	        if (!/".*#.*"/ &&!/.*"#.*"/ &&!/.*\{#.*/ &&!/.*\[#.*/ &&!/.*\(#.*/) {
		    s/#/#$ci-$num-/;
	            $num += 10;
		}
            }
        ' "${rutash[i]}"
    done
}

#Esta función elimina los comentarios de idioma de los .sh originales
function descomentar(){
    for ((i = 0; i < "$(wc -l <<< "$(find ./ -iname "*.sh" -not -path "./$(basename "$0")" 2>/dev/null)")"; i++)); do
        find "${rutash[i]}" -type f -exec perl -i -pe 's/(#[[:alnum:]]{2}-[0-9]+-)/#/' {} \;
    done
}

#Esta función crea un nuevo código de idioma, con sus txt y comentarios correspondientes.
function nuevaLengua() {
	echo -e "Los idiomas existentes son:"
	for ((i = 0; i < ${#todos_id[@]}; i++)); do
		echo "$((i+1)). ${todos_id[i]}"
	done
    echo -e "\nEscribe el nuevo código de idioma (2 caracteres):"
    read -n2 nuevo
    echo -e "\n\nEscribe el nombre completo del idioma:"
    read Idiomas_actuales
    nuevo_codigo=$(echo "$nuevo" | tr '[:lower:]' '[:upper:]')
    
    # Agregar el nuevo idioma a las arrays de identificadores y nombres de idiomas
    todos_id+=("$Idiomas_actuales")
    cod_idiomas+=("$nuevo_codigo")

    echo "##$nuevo_codigo-$Idiomas_actuales" >> "$0"

    # Crear el archivo .txt del nuevo idioma
    referenciar
    
    echo "Nuevo idioma '$Idiomas_actuales' creado."
}

# Esta función permite eliminar un idioma de las arrays de identificadores y nombres de idiomas
function eliminarIdioma() {
    grep -o "^##.*" $0 |  perl -i -ne 'print unless /^##/' "$0"
    echo "##ES-Español" >> "$0"
    echo "##FR-Frances" >> "$0"
    echo "##IN-Ingles" >> "$0"
}

#Buscar idiomas en el archivo del codigo
function buscar(){
    todos_id=()
    cod_idiomas=()
	while IFS= read -r linea; do
		todos_id+=("$linea")		
	done< <( grep -o "^##.*" $0 | cut -f2 -d "-")

	while IFS= read -r linea; do
		cod_idiomas+=("$linea")		
	done< <( grep -o "^##.*" $0| cut -f1 -d "-" | cut -c 3-)
}

#Cuerpo del programa, donde está el menu para elegir las opciones correspondientes
opcion=10
buscar
while [[ $opcion != 0 ]]; do
    echo -e "\n\t ------------- MENÚ PRINCIPAL -------------"
    echo -e "\t 1. Referenciar archivos"
    echo -e "\t 2. Volver a referenciar archivos"
    echo -e "\t 3. Cambiar comentarios por otro idioma"
    echo -e "\t 4. Crear un nuevo idioma"
    echo -e "\t 5. Descomentar archivos"
    echo -e "\t 6. Eliminar todos los idiomas creados"
    echo -e "\t 0. Salir"
    echo -e "\t ------------------------------------------\n"
   

    read -p "Seleccione una opción: " opcion
    echo -e "\n"

    case $opcion in
        1)
            echo -e "Has seleccionado la opción de referenciar los .sh\n"
            eleccion
            idioma
            referenciar
            ;;
        2)
            echo -e "Has seleccionado la opción de volver a referenciar los .sh\n"
            descomentar
            eleccion
            idioma
            referenciar
            ;;
        3)
            echo -e "Has seleccionado la opción cambiar a otro idioma \n"
            eleccion
            CambId
            ;;
        4)
            echo -e "Has seleccionado la opción de crear un nuevo idioma\n"
            nuevaLengua
            ;;
        5)
            echo -e "Has seleccionado la opción de descomentar los .sh\n"
            descomentar
            ;;
        6)
            echo -e "Has seleccionado la opción de eliminar todos los idiomas"
            for ((i = 0; i < ${#todos_id[@]}; i++)); do
        		echo "$((i+1)). ${todos_id[i]}"
        	done
            eliminarIdioma
            buscar
            echo -e "\nIdiomas resultantes"
            for ((i = 0; i < ${#todos_id[@]}; i++)); do
        		echo "$((i+1)). ${todos_id[i]}"
        	done
            ;;
        0)
            echo -e "Fin del programa\n"
            exit 0
            ;;
        *)
            echo -e "Opción no válida, por favor seleccione una opción del menú.\n"
            ;;
    esac
done
#Codigos de idioma
##ES-Español
##FR-Frances
##IN-Ingles
