CREATE TABLE UTILISATEUR (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    role ENUM('admin', 'utilisateur') DEFAULT 'utilisateur',
    date_inscription DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE DESTINATION (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    pays VARCHAR(100) NOT NULL,
    photo_principale VARCHAR(255) DEFAULT NULL
);

-- Hébergement
CREATE TABLE HEBERGEMENT (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_destination INT NOT NULL,
    nom VARCHAR(150) NOT NULL,
    prix_par_nuit DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (id_destination) REFERENCES DESTINATION(id) ON DELETE CASCADE
);

CREATE TABLE GROUPE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_destination INT NOT NULL,
    id_createur INT NOT NULL,
    nom VARCHAR(150) NOT NULL,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_destination) REFERENCES DESTINATION(id) ON DELETE RESTRICT,
    FOREIGN KEY (id_createur) REFERENCES UTILISATEUR(id) ON DELETE CASCADE
);

-- Permet de lier les amis au groupe
CREATE TABLE APPARTENIR (
    id_utilisateur INT NOT NULL,
    id_groupe INT NOT NULL,
    role_dans_groupe ENUM('chef', 'membre') DEFAULT 'membre',
    PRIMARY KEY (id_utilisateur, id_groupe),
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id) ON DELETE CASCADE,
    FOREIGN KEY (id_groupe) REFERENCES GROUPE(id) ON DELETE CASCADE
);
