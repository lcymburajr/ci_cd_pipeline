import { render, screen } from '@testing-library/react';
import App from '../App';

test('renders This is a cool', () => {
  render(<App />);
  const linkElement = screen.getByText(/This is cool!/i);
  expect(linkElement).toBeInTheDocument();
});
