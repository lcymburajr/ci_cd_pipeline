import { useEffect, useState } from 'react';
import axios from 'axios';
import logo from './img/logo.svg';
import './css/App.css';

const App = () => {
  const [hello, setHello] = useState('');

  useEffect(() => {
    const getHelloWorld = async () => {
      try {
        const res = await axios.get('/api/hello');

        setHello(res.data);
      } catch (err) {
        console.error(err.message);
      }
    }

    getHelloWorld();
  }, [])

  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          {hello}
        </p>
        <p>This is cool!</p>
        <p>yup!!!</p>
      </header>
    </div>
  );
}

export default App;
