import { LightningElement, api, wire, track } from 'lwc';
import getCheapestTransporter from '@salesforce/apex/TransporterSelector.getCheapestTransporter';
import getFastestTransporter from '@salesforce/apex/TransporterSelector.getFastestTransporter';
import getAccountDetails from '@salesforce/apex/OrderService.getAccountDetails';
import { refreshApex } from '@salesforce/apex';
import getReadyOrders from '@salesforce/apex/OrderService.getReadyOrders';
import launchDelivery from '@salesforce/apex/OrderService.launchDelivery';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCompatibleTransporters from '@salesforce/apex/TransporterSelector.getCompatibleTransporters';

export default class DeliveryLaunchInterface extends LightningElement {
    @track orders = []; // Liste des commandes disponibles
    @track selectedOrderId; // ID de la commande sélectionnée
    @track isLoading = false; // Indicateur de chargement
    @track deliveryCountry = 'France'; // Pays de livraison (par défaut France)
    @track cheapestTransporterName;
    @track cheapestPrice;
    @track cheapestDeliveryTime;
    @track fastestTransporterName;
    @track fastestPrice;
    @track fastestDeliveryTime;
    @track readyOrders = []; // Liste des commandes prêtes à être livrées
    @track customerType; // Type de client associé à la commande
    @track selectedTransporterId;
    @track compatibleTransporters = []; // Liste des transporteurs compatibles

    // Liste des options de pays disponibles
    countryOptions = [
        { label: 'France', value: 'France' },
        { label: 'Belgique', value: 'Belgique' },
        { label: 'Suisse', value: 'Suisse' },
        { label: 'Luxembourg', value: 'Luxembourg' }
    ];

    // Récupérer les commandes prêtes pour la livraison
    @wire(getReadyOrders)
    wiredOrders({ error, data }) {
        if (data) {
            //console.log('Commandes prêtes récupérées : ', data);
            this.readyOrders = [
                { label: 'Commande Test', value: '001000000000001' }, // Option statique pour test
                ...data.map(order => ({
                    label: order.Name,
                    value: order.Id
                }))
            ];
            //console.log('Options de la combobox :', this.readyOrders);
        } else if (error) {
            console.error('Erreur lors de la récupération des commandes prêtes : ', error);
            this.showToast('Erreur', 'Erreur lors de la récupération des commandes prêtes : ' + error.body.message, 'error');
        }
    }

    // Gérer la sélection d'un transporteur
    handleTransporterSelection(event) {
        this.selectedTransporterId = event.detail.value;
        //console.log('Transporteur sélectionné :', this.selectedTransporterId);
    }

    // Gestionnaire de changement de pays
    handleCountryChange(event) {
        this.deliveryCountry = event.detail.value;
        //console.log('Pays sélectionné :', this.deliveryCountry);
        this.getTransporters();
    }

    // Gérer la sélection d'une commande
    handleOrderSelection(event) {
        this.selectedOrderId = event.detail.value;
        //console.log('Commande sélectionnée :', this.selectedOrderId);

        // Appeler la méthode pour récupérer les transporteurs compatibles après avoir obtenu le type de client
        this.getAccountDetailsAndTransporters();
    }

    // Méthode pour récupérer le type de client et les transporteurs compatibles
    getAccountDetailsAndTransporters() {
        if (!this.selectedOrderId) {
            console.error('Aucune commande sélectionnée. Impossible de récupérer les transporteurs compatibles.');
            return;
        }

        this.isLoading = true;

        // Récupérer le type de client associé à la commande
        getAccountDetails({ orderId: this.selectedOrderId })
            .then((result) => {
                this.customerType = result.CustomerType__c;
                //console.log('Type de client récupéré :', this.customerType);

                // Une fois le type de client récupéré, obtenir les transporteurs compatibles
                return getCompatibleTransporters({ customerType: this.customerType });
            })
            .then((result) => {
                this.compatibleTransporters = result;
                //console.log('Transporteurs compatibles récupérés :', result);
            })
            .catch((error) => {
                console.error('Erreur lors de la récupération des transporteurs compatibles :', error);
                this.showToast('Erreur', 'Impossible de récupérer les transporteurs compatibles.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    // Confirmer et lancer la livraison
    confirmDelivery() {
    if (!this.selectedOrderId) {
        this.showToast('Erreur', 'Veuillez sélectionner une commande.', 'error');
        return;
    }

    if (!this.selectedTransporterId) {
        this.showToast('Erreur', 'Veuillez sélectionner un transporteur.', 'error');
        return;
    }

    console.log('Commande sélectionnée pour livraison : ', this.selectedOrderId);
    console.log('Transporteur sélectionné pour livraison : ', this.selectedTransporterId);

    this.isLoading = true;
    launchDelivery({ orderId: this.selectedOrderId, transporterId: this.selectedTransporterId })
        .then(() => {
            this.showToast('Succès', 'La livraison a été lancée avec succès.', 'success');
            return refreshApex(this.readyOrders); // Actualiser la liste des commandes prêtes
        })
        .catch(error => {
            console.error('Erreur lors du lancement de la livraison :', error);
            this.showToast('Erreur', 'Une erreur s\'est produite lors du lancement de la livraison.', 'error');
        })
        .finally(() => {
            this.isLoading = false;
        });

    }

    // Récupérer les transporteurs les moins chers et les plus rapides 
    getTransporters() {
        // Transporteur le moins cher
        getCheapestTransporter({ country: this.deliveryCountry })
            .then((result) => {
                if (result) {
                    this.cheapestTransporterName = result.transporterName;
                    this.cheapestPrice = result.deliveryPrice;
                    this.cheapestDeliveryTime = result.deliveryTime;
                    console.log('Transporteur le moins cher trouvé :', result);
                } else {
                    console.error('Aucun transporteur trouvé');
                }
            })
            .catch((error) => {
                console.error('Erreur lors de la récupération du transporteur le moins cher :', error);
                this.showToast('Erreur', 'Impossible de récupérer le transporteur le moins cher.', 'error');
            });

        // Transporteur le plus rapide
        getFastestTransporter({ country: this.deliveryCountry })
            .then((result) => {
                if (result) {
                    this.fastestTransporterName = result.transporterName;
                    this.fastestPrice = result.deliveryPrice;
                    this.fastestDeliveryTime = result.deliveryTime;
                    console.log('Transporteur le plus rapide trouvé :', result);
                } else {
                    console.error('Aucun transporteur trouvé');
                }
            })
            .catch((error) => {
                console.error('Erreur lors de la récupération du transporteur le plus rapide :', error);
                this.showToast('Erreur', 'Impossible de récupérer le transporteur le plus rapide.', 'error');
            });
    }

    // Afficher une notification (Toast)
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(event);
    }

    connectedCallback() {
        // Appeler la méthode de récupération des transporteurs lors de la connexion du composant
        this.getTransporters();
    }
}
