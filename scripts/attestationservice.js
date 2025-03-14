const axios = require('axios');

const AttestationStatus = {
    COMPLETE: 'complete',
    PENDING_CONFIRMATIONS: 'pending_confirmations',
};

const mapAttestation = (attestationResponse) => ({
    message: attestationResponse.attestation,
    status: attestationResponse.status,
});

const baseURL = 'https://iris-api-sandbox.circle.com/attestations';
const axiosInstance = axios.create({ baseURL });

/**
 * @param {string} messageHash 
 * @returns {Promise<{ message: string | null, status: string } | null>}
 */
const getAttestation = async (messageHash) => {
    try {
        const response = await axiosInstance.get(`/${messageHash}`);
        return mapAttestation(response.data);
    } catch (error) {
        // Treat 404 as pending and keep polling
        if (axios.isAxiosError(error) && error.response?.status === 404) {
            const response = {
                attestation: null,
                status: AttestationStatus.PENDING_CONFIRMATIONS,
            };
            return mapAttestation(response);
        } else {
            console.error(error);
            return null;
        }
    }
};

module.exports = { getAttestation };