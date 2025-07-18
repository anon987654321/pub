function MakeArray(size) {

    for (var i = 1; i <= size; i++) {
        this.length = size;
        this[i] = 0;
    }

}

/*
function N(X) // cumulative normal distr N(x)

{             //approximation from Hull chapter 10

    var x, k, y, gamma;

    if (X == 0) {

        return 0.5;
    }
    else {
        if (X > 0) {
            x = X;
        } else {
            x = -X;
        }
            with (Math) {

                gamma = 0.2316419;

                k = 1 / (1 + gamma * x);

                y = 1 - ((1 / sqrt(2 * PI)) * exp(-x * x * 0.5) * (k * 0.319381530 + k * k * (-0.356563782) +

                    k * k * k * 1.781477937 + k * k * k * k * (-1.821255978) + k * k * k * k * k * 1.330274429));

            }

        if (X < 0) {
            return 1 - y;
        }

        return y;
    }
}*/

function N(X) {
    var A1 = 0.31938153, A2 = -0.356563782, A3 = 1.781477937,
        A4 = -1.821255978, A5 = 1.330274429, L, K, W;

      with(Math) {
          L = abs(X);
          K = 1.0 / (1.0 + 0.2316419 * L);
          W = 1.0 - 1.0 / 2.5066282746310002 *
              exp(-L * L / 2.0) * (A1 * K + A2 * K * K + A3 * K*K*K + A4 * K*K*K*K
              + A5 * K*K*K*K*K);
      }
    if (X < 0) {
        return 1.0-W;
    } else {

        return W;
    }
}


function DN(x) // finds derivative of cumulative normal distr N(x)
{
    var pi, y;

    with (Math) {

        pi = 3.14159;
        y = exp(-x * x / 2) / pow(2 * pi, 1 / 2);
    }

    return y;
}


function BSput(S, X, sigma, q, r, Tdays)

    // Calculates Black-Scholes  price of Eur put
{
    var p, d1, d2, T;

    T = Tdays / 365;   // Time in years

    with (Math) {

        d1 = (log(S / X) + (r - q + sigma * sigma / 2) * T) / (sigma * sqrt(T));

        d2 = (log(S / X) + (r - q - sigma * sigma / 2) * T) / (sigma * sqrt(T));

        p = exp(-r * T) * X * N(-d2) - exp(-q * T) * S * N(-d1);

    }//end with(Math)

    return p;

}


function BScall(S, X, sigma, q, r, Tdays)

    // Calculates Black-Scholes  price of Eur Call

{

    var c, d1, d2, T;

    T = Tdays / 365;   // Time in years

    with (Math) {


        d1 = (log(S / X) + (r - q + sigma * sigma / 2) * T) / (sigma * sqrt(T));


        d2 = (log(S / X) + (r - q - sigma * sigma / 2) * T) / (sigma * sqrt(T));


        c = exp(-q * T) * S * N(d1) - exp(-r * T) * X * N(d2);

    }//end with(Math)

    return c;

}

function BSdeltaCall(S, X, sigma, q, r, Tdays) {
    var c, d1, d2, T;
    T = Tdays / 365;   // Time in years
    with (Math) {
        d1 = (log(S / X) + (r - q + sigma * sigma / 2) * T) / (sigma * sqrt(T));
        c = exp(-r * T) * N(d1)
    }//end with(Math)
    return c;
}

function BSdeltaPut(S, X, sigma, q, r, Tdays) {
    var c, d1, d2, T;
    T = Tdays / 365;   // Time in years
    with (Math) {
        d1 = (log(S / X) + (r - q + sigma * sigma / 2) * T) / (sigma * sqrt(T));
        c = exp(-r * T) * (N(d1) - 1)
    }//end with(Math)
    return c;
}


function BScallderivative(S, X, sigma, q, r, Tdays)

    // Calculates the derivative with respect to
    // sigma of the Black-Scholes  price of Eur Call

{

    var c, d1, d2, T;
    var dc, dd1, dd2;       // derivatives with respect to sigma of c, d1, d2

    T = Tdays / 365;   // Time in years

    with (Math) {


        d1 = (log(S / X) + (r - q + sigma * sigma / 2) * T) / (sigma * sqrt(T));

        d2 = (log(S / X) + (r - q - sigma * sigma / 2) * T) / (sigma * sqrt(T));

        dd1 = (T * (sigma * sigma / 2 - r - q) - log(S / X)) / (sigma * sigma * pow(T, 1 / 2));

        dd2 = dd1 - pow(T, 1 / 2);

        dc = exp(-q * T) * S * DN(d1) * dd1 - exp(-r * T) * X * DN(d2) * dd2;

    }//end with(Math)

    return dc;

}


function BScallvolatility(S, X, guess, q, r, Tdays, c) {
    // Calculates the volatility from an initial guess when all
    // other parameters are known (including the price c)


    var approx = guess;


    with (Math) {

        for (var i = 1; i <= 10; i++)   // implementing Newton's method
        {

            approx = approx -
                (BScall(S, X, approx, q, r, Tdays) - c) /
                BScallderivative(S, X, approx, q, r, Tdays);

        }

    }

    return approx;

}

function BSPrice(Type, S, X, T, V, IR) {
    var r = 0.0;

    if ((typeof IR) === 'number') {
        r = IR;
    }

    if (Type == 'call') {
        return BScall(S, X, V/100.0, 0.0, r, T);
    }

    return BSput(S, X, V/100.0, 0.0, r, T);
}

function BSDelta(Type, S, X, T, V, IR) {
    var r = 0.0;

    if ((typeof IR) === 'number') {
        r = IR;
    }

    if (Type == 'call') {
        return BSdeltaCall(S, X, V, 0.0, r, T);
    } else {
        return BSdeltaPut(S, X, V, 0.0, r, T)
    }
}


function BSImpV(Type, S, X, T, c, IR) {
    var i, approx = 5, tol = 0.00001, err,
        sig = 0.5, sig_u = 5, sig_d = 0.0001,
        r = 0.0;

    if ((typeof IR) === 'number') {
        r = IR;
    }

    if (Type == 'call') {
        with (Math) {

            i = 0;
            err = BScall(S, X, sig, 0, r, T) - c;

            while(i<32 && abs(err) > tol) {

                if (err < 0) {
                    sig_d = sig;
                    sig = (sig_u + sig)/2.0;
                } else if (err > 0) {
                    sig_u = sig;
                    sig = (sig_d + sig)/2.0;
                } else {
                    return sig;
                }

                err = BScall(S, X, sig, 0, r, T) - c;
                i = i + 1;
            }
        }
        return sig;

    } else {
        with (Math) {

            i = 0;
            err = BSput(S, X, sig, 0, r, T) - c;

            while(i<32 && abs(err) > tol) {

                if (err < 0) {
                    sig_d = sig;
                    sig = (sig_u + sig)/2.0;
                } else {
                    sig_u = sig;
                    sig = (sig_d + sig)/2.0;
                }

                err = BSput(S, X, sig, 0, r, T) - c;
                i = i + 1;
            }
        }
        return sig;
    }

}


function AmPut(S, X, sigma, Q, r, Tdays, Nofnodes)

    //Calculation of Eur and Am Put using BINOMIAL TREE
    //Function also returns the value of Amer Put in a normal way.

{
    var T, dt, a, b2, u, d, p, q; //q=1-p the rest see in Hull p.337
    //do not confuse q with dividents Q

    P0 = new MakeArray(Nofnodes);

    P1 = new MakeArray(Nofnodes);//American Put Prices

    // In array P0[*]
    //we keep stock prices and in P1[*] american option prices
    // at a fixed moment P0[0] is the lowest stock price
    //i.e. P is a vertical section of the tree (tree isgrowing from
    //left to right see picture in Hull

    T = Tdays / 365;       // Time in years

    dt = T / (Nofnodes - 1); //Number of time intervals is Nofnodes -1

    with (Math) {
        a = exp((r - Q) * dt);

        b2 = a * a * (exp(sigma * sigma * dt) - 1); //b2=b^2
        u = ((a * a + b2 + 1) + sqrt((a * a + b2 + 1) * (a * a + b2 + 1) - 4 * a * a)) / (2 * a);
        //u=exp(sigma*dt); OLD CoxRossRubinstein where prob can be
        //negative
    }

    d = 1 / u;

    p = (a - d) / (u - d);

    q = 1 - p;

    if ((q > 0) && (p > 0))//positive probabilities, calculate the prices

    {

        //calculation of terminal prices and values of the option

        //at time i*dt prices are S*u^j*d^(i-j)  j=0,1,...i


        var i = Nofnodes;

        with (Math) {
            P0[0] = S * pow(d, i - 1);
        } //i is the number of prices

        if (P0[0] <= X)

            P1[0] = X - P0[0];

        else

            P1[0] = 0;


        for (j = 1; j <= i - 1; ++j) {

            P0[j] = P0[j - 1] * (u / d);

            if (P0[j] <= X)

                P1[j] = X - P0[j];

            else

                P1[j] = 0;

        }

        //End of calculation terminal prices of Am Option

        // Calculation of dt-period  discount rate

        with (Math) {
            var daydiscount = exp(-r * dt);
        }

        //going backwards through the tree
        //Calculating American Put

        for (k = Nofnodes; k >= 1; --k) //changing time

        {

            for (l = 0; l < k - 1; ++l) //changing entries for stock prices

                //and opt prices using nodes from the previous t

            {

                P0[l] = P0[l] * u; //put new stock price

                P1[l] = (q * (P1[l]) + p * (P1[l + 1])) * daydiscount;

                //check for early exercize

                if (P1[l] < (X - P0[l])) //then exercize

                {
                    P1[l] = X - P0[l];
                }
            }
        }

        return P1[0]; //returns american put price

    }
    else //negative probabilities Do Not Exist in Our Approximation

    {
        alert('Negative probabilities, Increase Volatility');
        return "error";
    }

}//end AmPut

function EurPut(S, X, sigma, Q, r, Tdays, Nofnodes) {

    //Calculation of Eur Put using BINOMIAL TREE

    var T, dt, a, b2, u, d, p, q; //q=1-p the rest see in Hull p.337
    //do not confuse q with dividents Q


    Q0 = new MakeArray(Nofnodes);

    Q1 = new MakeArray(Nofnodes);//European Put Prices

    // In array Q0[*]
    //and in Q1[*] european option prices
    // at a fixed moment Q0[0] is the lowest stock price
    //i.e. P is a vertical section of the tree (tree isgrowing from
    //left to right see picture in Hull

    T = Tdays / 365;       // Time in years

    dt = T / (Nofnodes - 1); //Number of time intervals is Nofnodes -1

    with (Math) {
        a = exp((r - Q) * dt);


        b2 = a * a * (exp(sigma * sigma * dt) - 1); //b2=b^2
        u = ((a * a + b2 + 1) + sqrt((a * a + b2 + 1) * (a * a + b2 + 1) - 4 * a * a)) / (2 * a);
        //u=exp(sigma*dt); OLD CoxRossRubinstein where prob can be
        //negative
    }

    d = 1 / u;

    p = (a - d) / (u - d);

    q = 1 - p;

    if ((q > 0) && (p > 0))//positive probabilities, calculate the prices

    {

        //calculation of terminal prices and values of the option

        //at time i*dt prices are S*u^j*d^(i-j)  j=0,1,...i


        var i = Nofnodes;

        with (Math) {
            Q0[0] = S * pow(d, i - 1);
        } //i is the number of prices

        if (Q0[0] <= X)

            Q1[0] = X - Q0[0];

        else

            Q1[0] = 0;


        for (j = 1; j <= i - 1; ++j) {

            Q0[j] = Q0[j - 1] * (u / d);

            if (Q0[j] <= X)

                Q1[j] = X - Q0[j];

            else

                Q1[j] = 0;

        }

        //End of calculation terminal prices of Am Option


        // Calculation of dt-period  discount rate

        with (Math) {
            var daydiscount = exp(-r * dt);
        }


        //going backwards through the tree
        //Calculating Eur Put


        for (k = Nofnodes; k >= 1; --k) //changing time

        {

            for (l = 0; l < k - 1; ++l) //changing entries for stock prices
                //and opt prices using nodes from the previous t

            {

                Q0[l] = Q0[l] * u; //put new stock price

                Q1[l] = (q * (Q1[l]) + p * (Q1[l + 1])) * daydiscount;

                //no check for early exercize

            }
        }


        return Q1[0];

    }// end if positive probabilities


    else //negative probabilities Do Not Exist in Our Approximation This is
    //from old times
    {
        alert('Negative probabilities, Increase Volatility');
        return "error";
    }

}//end EurPut

function AmCall(S, X, sigma, Q, r, Tdays, Nofnodes)

    //Calculation of Eur and Am Put using BINOMIAL TREE
    //Function also returns the value of Amer Put in a normal way.

{
    var T, dt, a, b2, u, d, p, q; //q=1-p the rest see in Hull p.337
    //do not confuse q with dividents Q

    P0 = new MakeArray(Nofnodes);

    P1 = new MakeArray(Nofnodes);//American Put Prices

    // In array P0[*]
    //we keep stock prices and in P1[*] american option prices
    // at a fixed moment P0[0] is the lowest stock price
    //i.e. P is a vertical section of the tree (tree isgrowing from
    //left to right see picture in Hull

    T = Tdays / 365;       // Time in years

    dt = T / (Nofnodes - 1); //Number of time intervals is Nofnodes -1

    with (Math) {
        a = exp((r - Q) * dt);

        b2 = a * a * (exp(sigma * sigma * dt) - 1); //b2=b^2
        u = ((a * a + b2 + 1) + sqrt((a * a + b2 + 1) * (a * a + b2 + 1) - 4 * a * a)) / (2 * a);
        //u=exp(sigma*dt); OLD CoxRossRubinstein where prob can be
        //negative
    }

    d = 1 / u;

    p = (a - d) / (u - d);

    q = 1 - p;

    if ((q > 0) && (p > 0))//positive probabilities, calculate the prices

    {

        //calculation of terminal prices and values of the option

        //at time i*dt prices are S*u^j*d^(i-j)  j=0,1,...i


        var i = Nofnodes;

        with (Math) {
            P0[0] = S * pow(d, i - 1);
        } //i is the number of prices

        if (P0[0] >= X)

            P1[0] = P0[0] - X;

        else

            P1[0] = 0;


        for (j = 1; j <= i - 1; ++j) {

            P0[j] = P0[j - 1] * (u / d);

            if (P0[j] >= X)

                P1[j] = P0[j] - X;

            else

                P1[j] = 0;

        }

        //End of calculation terminal prices of Am Option

        // Calculation of dt-period  discount rate

        with (Math) {
            var daydiscount = exp(-r * dt);
        }

        //going backwards through the tree
        //Calculating American Put

        for (k = Nofnodes; k >= 1; --k) //changing time

        {

            for (l = 0; l < k - 1; ++l) //changing entries for stock prices

                //and opt prices using nodes from the previous t

            {

                P0[l] = P0[l] * u; //put new stock price

                P1[l] = (q * (P1[l]) + p * (P1[l + 1])) * daydiscount;

                //check for early exercize

                if (P1[l] < (P0[l] - X)) //then exercize

                {
                    P1[l] = P0[l] - X;
                }
            }
        }

        return P1[0]; //returns american call price

    }
    else //negative probabilities Do Not Exist in Our Approximation

    {
        alert('Negative probabilities, Increase Volatility');
        return "error";
    }

}//end AmCall

function EurCall(S, X, sigma, Q, r, Tdays, Nofnodes) {

    //Calculation of Eur Call using BINOMIAL TREE

    var T, dt, a, b2, u, d, p, q; //q=1-p the rest see in Hull p.337
    //do not confuse q with dividents Q


    Q0 = new MakeArray(Nofnodes);

    Q1 = new MakeArray(Nofnodes);//European Call Prices

    // In array Q0[*]
    //and in Q1[*] european option prices
    // at a fixed moment Q0[0] is the lowest stock price
    //i.e. P is a vertical section of the tree (tree isgrowing from
    //left to right see picture in Hull

    T = Tdays / 365;       // Time in years

    dt = T / (Nofnodes - 1); //Number of time intervals is Nofnodes -1

    with (Math) {
        a = exp((r - Q) * dt);


        b2 = a * a * (exp(sigma * sigma * dt) - 1); //b2=b^2
        u = ((a * a + b2 + 1) + sqrt((a * a + b2 + 1) * (a * a + b2 + 1) - 4 * a * a)) / (2 * a);
        //u=exp(sigma*dt); OLD CoxRossRubinstein where prob can be
        //negative
    }

    d = 1 / u;

    p = (a - d) / (u - d);

    q = 1 - p;

    if ((q > 0) && (p > 0))//positive probabilities, calculate the prices

    {

        //calculation of terminal prices and values of the option

        //at time i*dt prices are S*u^j*d^(i-j)  j=0,1,...i


        var i = Nofnodes;

        with (Math) {
            Q0[0] = S * pow(d, i - 1);
        } //i is the number of prices

        if (Q0[0] >= X)     //here is the  change from call to put

            Q1[0] = Q0[0] - X; //here is the  change from call to put

        else

            Q1[0] = 0;


        for (j = 1; j <= i - 1; ++j) {

            Q0[j] = Q0[j - 1] * (u / d);

            if (Q0[j] >= X) //here is the  change from call to put

                Q1[j] = Q0[j] - X;//here is the  change from call to put

            else

                Q1[j] = 0;

        }

        //End of calculation terminal prices of Eur


        // Calculation of dt-period  discount rate

        with (Math) {
            var daydiscount = exp(-r * dt);
        }


        //going backwards through the tree
        //Calculating Eur Put


        for (k = Nofnodes; k >= 1; --k) //changing time

        {

            for (l = 0; l < k - 1; ++l) //changing entries for stock prices
                //and opt prices using nodes from the previous t

            {

                Q0[l] = Q0[l] * u; //put new stock price

                Q1[l] = (q * (Q1[l]) + p * (Q1[l + 1])) * daydiscount;

                //no check for early exercize

            }
        }

        return Q1[0];

    }// end if positive probabilities


    else //negative probabilities Do Not Exist in Our Approximation This is
    //from old times
    {
        alert('Negative probabilities, Increase Volatility');
        return "error";
    }

}//end EurCall

