-- Création de la base de données
CREATE DATABASE IF NOT EXISTS voyagevista_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE voyagevista_db;

CREATE TABLE UTILISATEUR (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL, -- Haché via password_hash() en PHP
    photo_profil VARCHAR(255) DEFAULT NULL,
    role ENUM('admin', 'utilisateur') DEFAULT 'utilisateur',
    est_prestataire BOOLEAN DEFAULT FALSE,
    date_inscription DATETIME DEFAULT CURRENT_TIMESTAMP,
    est_actif BOOLEAN DEFAULT TRUE
);

-- 2. CATALOGUE (Destinations, Transports, Activités, Hébergements)

CREATE TABLE DESTINATION (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    pays VARCHAR(100) NOT NULL,
    continent VARCHAR(100) NOT NULL,
    description TEXT,
    photo_principale VARCHAR(255) DEFAULT NULL,
    type VARCHAR(50) DEFAULT NULL, -- ex: Plage, Montagne, Ville
    est_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE TRANSPORT (
    id INT AUTO_INCREMENT PRIMARY KEY,
    type ENUM('avion', 'train', 'bus', 'ferry') NOT NULL,
    compagnie VARCHAR(100) NOT NULL,
    ville_depart VARCHAR(100) NOT NULL,
    ville_arrivee VARCHAR(100) NOT NULL,
    date_depart DATE NOT NULL,
    heure_depart TIME NOT NULL,
    date_arrivee DATE NOT NULL,
    heure_arrivee TIME NOT NULL,
    prix_par_personne DECIMAL(10, 2) NOT NULL,
    places_disponibles INT NOT NULL,
    est_actif BOOLEAN DEFAULT TRUE
);

CREATE TABLE ACTIVITE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_destination INT NOT NULL,
    nom VARCHAR(150) NOT NULL,
    description TEXT,
    categorie VARCHAR(50) DEFAULT NULL, -- ex: Culture, Sport, Détente
    duree_heures DECIMAL(4, 2) NOT NULL,
    prix_par_personne DECIMAL(10, 2) NOT NULL,
    capacite_max INT NOT NULL,
    photo VARCHAR(255) DEFAULT NULL,
    est_active BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (id_destination) REFERENCES DESTINATION(id) ON DELETE CASCADE
);

CREATE TABLE HEBERGEMENT (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_destination INT NOT NULL,
    id_proprietaire INT NOT NULL,
    nom VARCHAR(150) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL, -- ex: Hôtel, Appartement, Villa
    adresse VARCHAR(255) NOT NULL,
    ville VARCHAR(100) NOT NULL,
    capacite_max INT NOT NULL,
    prix_par_nuit DECIMAL(10, 2) NOT NULL,
    equipements JSON, -- Stockage natif JSON pour plus de flexibilité (ex: ["wifi", "piscine"])
    photo_principale VARCHAR(255) DEFAULT NULL,
    statut ENUM('en_attente_validation', 'publie', 'rejete', 'suspendu') DEFAULT 'en_attente_validation',
    FOREIGN KEY (id_destination) REFERENCES DESTINATION(id) ON DELETE CASCADE,
    FOREIGN KEY (id_proprietaire) REFERENCES UTILISATEUR(id) ON DELETE CASCADE
);

CREATE TABLE DISPONIBILITE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_hebergement INT NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    statut ENUM('disponible', 'reserve', 'bloque') DEFAULT 'disponible',
    FOREIGN KEY (id_hebergement) REFERENCES HEBERGEMENT(id) ON DELETE CASCADE
);

-- 3. GESTION DES GROUPES ET INVITATIONS

CREATE TABLE GROUPE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_destination INT NOT NULL,
    id_createur INT NOT NULL,
    nom VARCHAR(150) NOT NULL,
    description TEXT,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    budget_max_par_personne DECIMAL(10, 2) DEFAULT NULL,
    statut ENUM('en_creation', 'valide', 'archive') DEFAULT 'en_creation',
    FOREIGN KEY (id_destination) REFERENCES DESTINATION(id) ON DELETE RESTRICT,
    FOREIGN KEY (id_createur) REFERENCES UTILISATEUR(id) ON DELETE CASCADE
);

CREATE TABLE APPARTENIR (
    id_utilisateur INT NOT NULL,
    id_groupe INT NOT NULL,
    role_dans_groupe ENUM('chef', 'membre') DEFAULT 'membre',
    date_rejoindre DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_utilisateur, id_groupe),
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id) ON DELETE CASCADE,
    FOREIGN KEY (id_groupe) REFERENCES GROUPE(id) ON DELETE CASCADE
);

CREATE TABLE INVITATION (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_groupe INT NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_expiration DATETIME NOT NULL,
    est_utilisee BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_groupe) REFERENCES GROUPE(id) ON DELETE CASCADE
);

-- 4. PLANIFICATION ET ITINÉRAIRE (Cœur métier)

CREATE TABLE RECOMMANDATION (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_groupe INT NOT NULL,
    id_utilisateur INT NOT NULL,
    type_contenu ENUM('hebergement', 'activite') NOT NULL,
    id_hebergement INT DEFAULT NULL,
    id_activite INT DEFAULT NULL,
    commentaire TEXT,
    date_recommandation DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_groupe) REFERENCES GROUPE(id) ON DELETE CASCADE,
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id) ON DELETE CASCADE,
    FOREIGN KEY (id_hebergement) REFERENCES HEBERGEMENT(id) ON DELETE CASCADE,
    FOREIGN KEY (id_activite) REFERENCES ACTIVITE(id) ON DELETE CASCADE,
    CHECK (
        (type_contenu = 'hebergement' AND id_hebergement IS NOT NULL AND id_activite IS NULL) OR 
        (type_contenu = 'activite' AND id_activite IS NOT NULL AND id_hebergement IS NULL)
    )
);

CREATE TABLE ITINERAIRE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_groupe INT NOT NULL UNIQUE, -- Un groupe n'a qu'un seul itinéraire actif
    id_transport_aller INT DEFAULT NULL,
    id_transport_retour INT DEFAULT NULL,
    id_hebergement INT DEFAULT NULL,
    date_debut DATE,
    date_fin DATE,
    nb_voyageurs INT DEFAULT 1,
    cout_total DECIMAL(10, 2) DEFAULT 0.00,
    cout_par_personne DECIMAL(10, 2) DEFAULT 0.00,
    statut ENUM('brouillon', 'pret_au_paiement', 'paye') DEFAULT 'brouillon',
    FOREIGN KEY (id_groupe) REFERENCES GROUPE(id) ON DELETE CASCADE,
    FOREIGN KEY (id_transport_aller) REFERENCES TRANSPORT(id) ON DELETE SET NULL,
    FOREIGN KEY (id_transport_retour) REFERENCES TRANSPORT(id) ON DELETE SET NULL,
    FOREIGN KEY (id_hebergement) REFERENCES HEBERGEMENT(id) ON DELETE SET NULL
);

CREATE TABLE ITINERAIRE_ACTIVITE (
    id_itineraire INT NOT NULL,
    id_activite INT NOT NULL,
    date_activite DATE NOT NULL,
    heure_activite TIME NOT NULL,
    PRIMARY KEY (id_itineraire, id_activite),
    FOREIGN KEY (id_itineraire) REFERENCES ITINERAIRE(id) ON DELETE CASCADE,
    FOREIGN KEY (id_activite) REFERENCES ACTIVITE(id) ON DELETE CASCADE
);

-- 5. RÉSERVATION, PAIEMENT ET NOTIFICATIONS

CREATE TABLE RESERVATION (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_itineraire INT NOT NULL,
    id_groupe INT NOT NULL,
    id_chef INT NOT NULL,
    reference_reservation VARCHAR(50) NOT NULL UNIQUE,
    date_reservation DATETIME DEFAULT CURRENT_TIMESTAMP,
    montant_total DECIMAL(10, 2) NOT NULL,
    statut ENUM('en_attente', 'confirmee', 'annulee') DEFAULT 'en_attente',
    FOREIGN KEY (id_itineraire) REFERENCES ITINERAIRE(id) ON DELETE RESTRICT,
    FOREIGN KEY (id_groupe) REFERENCES GROUPE(id) ON DELETE RESTRICT,
    FOREIGN KEY (id_chef) REFERENCES UTILISATEUR(id) ON DELETE RESTRICT
);

CREATE TABLE PAIEMENT (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_reservation INT NOT NULL,
    montant DECIMAL(10, 2) NOT NULL,
    date_paiement DATETIME DEFAULT CURRENT_TIMESTAMP,
    methode VARCHAR(50) DEFAULT 'carte_bancaire', -- Simulation
    statut ENUM('en_attente', 'valide', 'echoue', 'rembourse') DEFAULT 'en_attente',
    numero_carte_masque VARCHAR(20) DEFAULT NULL,
    FOREIGN KEY (id_reservation) REFERENCES RESERVATION(id) ON DELETE RESTRICT
);

CREATE TABLE NOTIFICATION (
    id INT AUTO_INCREMENT PRIMARY KEY,
    id_utilisateur INT NOT NULL,
    id_groupe INT DEFAULT NULL,
    id_reservation INT DEFAULT NULL,
    type VARCHAR(50) NOT NULL, -- ex: 'nouvelle_recommandation', 'reservation_confirmee', 'rappel_paiement'
    message TEXT NOT NULL,
    est_lue BOOLEAN DEFAULT FALSE,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR(id) ON DELETE CASCADE,
    FOREIGN KEY (id_groupe) REFERENCES GROUPE(id) ON DELETE CASCADE,
    FOREIGN KEY (id_reservation) REFERENCES RESERVATION(id) ON DELETE CASCADE
);
