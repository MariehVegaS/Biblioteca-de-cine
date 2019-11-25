const express = require('express');
const oracledb = require('oracledb');
const database = require('./database');
const connectionName = 'BibliotecaCine';
const bodyParser = require('body-parser');


const app = express();
const router = express.Router();
const port = process.env.PORT || 3000;
process.env.UV_THREADPOOL_SIZE = 3;

app.use(bodyParser.urlencoded({extended: false}));
        /*/Will parse incoming JSON requests and revive ISO 8601 string to instances of Date.*/
app.use(bodyParser.json());

router.route('/artists')
    .get(async (req, res) => {
        //const request = new oracledb.request();
        const binds = {};
        const query =`SELECT ARTIST_COD "artistCod",
        ARTIST_NAME "artistName",
        GENRE "genre",
        BIOGRAFY "biografy"
        FROM ARTISTS`;
        const result = await database.simpleExecute(connectionName, query, []);

        //return result.rows;
        /*const response = {hello: 'This is my API'};*/
        console.log(result);
        res.json(result.rows); 
    })
    .post(async (req, res) => {
        
        const artist = {
           
            artist_name: req.body.artistName,
            genre: req.body.genre,
            biografy: req.body.biografy
            
        }
        const insertSql = 
        `INSERT INTO ARTISTS (ARTIST_NAME, GENRE, BIOGRAFY) VALUES (:artist_name, :genre, :biografy)`;

        /* HACIENDO USO DE UN PROCEDIMIENTO PREVIAMENTE CREADO EN LA BASE DE DATOS
        const createSql =
        `BEGIN Insertar_ImagenBD(:artist_name, :genre, :biografy, :img_name); END;`;*/

        const result = await database.simpleExecute(connectionName, insertSql, artist);

        //return result.rows;
        /*const response = {hello: 'This is my API'};*/
        console.log(result);
        res.json(result); 
    });
router.route('/artists/:id')

    .put(async (req, res) => {
        
        const artist = {
            artist_cod: parseInt(req.params.id),
            artist_name: req.body.artistName,
            genre: req.body.genre,
            biografy: req.body.biografy
            
        }
    
        const updateSql =
        `UPDATE ARTISTS SET
        ARTIST_NAME = :artist_name,
        GENRE = :genre,
        BIOGRAFY = :biografy
        
        WHERE ARTIST_COD = :artist_cod`;

        const result = await database.simpleExecute(connectionName, updateSql, artist);

        //return result.rows;
        /*const response = {hello: 'This is my API'};*/
        console.log(result);
        res.json(result); 
    })
    .delete( async (req, res) =>{
        const artist = {
            artist_cod: parseInt(req.params.id)           
        }
        const deleteSql =
        `DELETE ARTISTS WHERE ARTIST_COD = :artist_cod`;

        const result = await database.simpleExecute(connectionName, deleteSql, artist);

        //return result.rows;
        /*const response = {hello: 'This is my API'};*/
        console.log(result);
        res.json(result); 
    });

app.use('/api', router);

app.get('/', (req, res) => {
    res.send('Welcome to my API!');
        
});

startup();


async function startup() {
    console.log('Starting application');

    try{
        console.log('Opening connection to databases');

        await database.openConnections();

        console.log('Starting web server');

        app.listen(port, () => {
            console.log('Running on port ' + port);
        });
    } catch (err){
        console.log('Encountered error', err);

        process.exit(1);
    }

};