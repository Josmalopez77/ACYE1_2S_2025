export const styles = {
  container: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    padding: '20px',
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
  },
  maxWidth: {
    maxWidth: '1280px',
    margin: '0 auto'
  },
  card: {
    background: 'rgba(255, 255, 255, 0.95)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    boxShadow: '0 10px 30px rgba(0, 0, 0, 0.1)',
    border: '1px solid rgba(255, 255, 255, 0.2)'
  },
  header: {
    padding: '30px',
    marginBottom: '30px'
  },
  headerContent: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: '20px'
  },
  title: {
    fontSize: '2.5rem',
    fontWeight: '800',
    color: '#1a202c',
    margin: 0,
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
    WebkitBackgroundClip: 'text',
    WebkitTextFillColor: 'transparent',
    backgroundClip: 'text'
  },
  subtitle: {
    color: '#718096',
    marginTop: '8px',
    fontSize: '1.1rem'
  },
  statusConnected: {
    display: 'flex',
    alignItems: 'center',
    color: '#38a169',
    fontSize: '14px',
    fontWeight: '600',
    background: 'rgba(56, 161, 105, 0.1)',
    padding: '8px 16px',
    borderRadius: '25px',
    border: '1px solid rgba(56, 161, 105, 0.2)'
  },
  statusDisconnected: {
    display: 'flex',
    alignItems: 'center',
    color: '#e53e3e',
    fontSize: '14px',
    fontWeight: '600',
    background: 'rgba(229, 62, 62, 0.1)',
    padding: '8px 16px',
    borderRadius: '25px',
    border: '1px solid rgba(229, 62, 62, 0.2)'
  },
  statCard: {
    background: 'rgba(255, 255, 255, 0.9)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    padding: '25px',
    boxShadow: '0 8px 25px rgba(0, 0, 0, 0.08)',
    border: '1px solid rgba(255, 255, 255, 0.3)',
    transition: 'all 0.3s ease',
    cursor: 'pointer'
  },
  statCardHover: {
    transform: 'translateY(-5px)',
    boxShadow: '0 15px 40px rgba(0, 0, 0, 0.15)'
  },
  iconContainer: {
    width: '50px',
    height: '50px',
    borderRadius: '12px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: '15px'
  },
  temperatureIcon: {
    background: 'linear-gradient(135deg, #ff6b6b, #ee5a24)'
  },
  statLabel: {
    fontSize: '14px',
    color: '#718096',
    fontWeight: '600',
    marginBottom: '8px',
    textTransform: 'uppercase',
    letterSpacing: '0.5px'
  },
  statValue: {
    fontSize: '2.2rem',
    fontWeight: '800',
    color: '#1a202c',
    lineHeight: '1'
  },
  statSubtext: {
    fontSize: '12px',
    color: '#a0aec0',
    marginTop: '10px'
  },
  tableContainer: {
    background: 'rgba(255, 255, 255, 0.95)',
    backdropFilter: 'blur(10px)',
    borderRadius: '16px',
    overflow: 'hidden',
    boxShadow: '0 10px 30px rgba(0, 0, 0, 0.1)'
  },
  tableHeader: {
    padding: '25px',
    borderBottom: '1px solid rgba(0, 0, 0, 0.08)'
  },
  tableHeaderContent: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: '15px'
  },
  tableTitle: {
    fontSize: '1.5rem',
    fontWeight: '700',
    color: '#1a202c'
  },
  buttonGroup: {
    display: 'flex',
    gap: '10px'
  },
  button: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    padding: '12px 20px',
    borderRadius: '10px',
    border: 'none',
    fontWeight: '600',
    fontSize: '14px',
    cursor: 'pointer',
    transition: 'all 0.3s ease',
    textTransform: 'uppercase',
    letterSpacing: '0.5px'
  },
  secondaryButton: {
    background: 'linear-gradient(135deg, #11998e, #38ef7d)',
    color: 'white'
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse'
  },
  tableHead: {
    background: 'linear-gradient(135deg, #f8fafc, #e2e8f0)'
  },
  th: {
    padding: '16px 24px',
    textAlign: 'left',
    fontSize: '12px',
    fontWeight: '700',
    color: '#4a5568',
    textTransform: 'uppercase',
    letterSpacing: '1px',
    borderBottom: '2px solid #e2e8f0'
  },
  td: {
    padding: '16px 24px',
    borderBottom: '1px solid #f1f5f9',
    fontSize: '14px',
    color: '#2d3748'
  },
  tableRow: {
    transition: 'all 0.2s ease'
  },
  valueDisplay: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    fontWeight: '600'
  },
  loadingContainer: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    padding: '40px',
    color: '#667eea'
  },
  pagination: {
    background: 'white',
    padding: '20px 24px',
    borderTop: '1px solid #e2e8f0',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: '15px'
  },
  paginationInfo: {
    fontSize: '14px',
    color: '#718096'
  },
  paginationButtons: {
    display: 'flex',
    gap: '5px'
  },
  pageButton: {
    padding: '8px 12px',
    border: '1px solid #e2e8f0',
    backgroundColor: 'white',
    color: '#4a5568',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '14px',
    fontWeight: '500',
    transition: 'all 0.2s ease'
  },
  activePageButton: {
    background: 'linear-gradient(135deg, #667eea, #764ba2)',
    color: 'white',
    border: '1px solid #667eea'
  }
};