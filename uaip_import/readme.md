# Scripts para importar datos del Catálogo de Datos Abiertos

Este directorio contiene los scripts para normalizar las entidades de la base de datos actual e importar los [datos de los responsables de transparencia del Catálogo de Datos Abiertos publicados por la UAIP](https://catalogodatos.gub.uy/dataset/datos-de-responsables-de-transparencia). [Discusión inicial aquí](https://github.com/datauy/quesabes-theme/issues/26).

# normalize.rb

```bash
cd alaveteli # correr desde el directorio root de la aplicación Rails
bundle exec rails runner ../quesabes-data/uaip_import/normalize.rb
```

# import.rb

Este script descarga los últimos datos publicados y si detecta que se necesita actualizar, muestra la lista de cambios que se realizarán en la base. Luego se pregunta al usuario si desea aplicar los cambios listados o no. Antes de correr este script, asegurarse que los nombres de los organismos estén normalizados corriendo el script anterior (`normalize.rb`), para que coincidan con los datos de la UAIP.

```bash
cd alaveteli # correr desde el directorio root de la aplicación Rails
bundle exec rails runner ../quesabes-data/uaip_import/import.rb
```
