# optimization_assistant

The Optimization Assisstant is a proof-of-concept simulation to demonstrate how data-driven optimization can be used as an interactive recommender system to facilitate DBS programming. The goal is to identify the minimum of an unknown randomly generated objective function by iteratively selecting stimulation settings and recording the result. *This software is not intended or approved for clinical use*

To start the Optimization Assistant, run 'start_optimization_assistant.m'. This script will add the necessary code and utilies to your path and start the application.
![Slide1](https://user-images.githubusercontent.com/66339367/111886360-7c1ecd00-89a3-11eb-95e6-cf8071b25924.jpeg)

The user can then either specify a stimulation setting in terms of stimulating cathode and anode, the ampltitude, and the frequency. Setting the cathode and anode to the same value is interpreted as monopolar stimulation between the cathode and the case. Pulse width is currently not implemented
![Slide2](https://user-images.githubusercontent.com/66339367/111886372-82ad4480-89a3-11eb-86cb-8079bed28544.jpeg)

Alternatively, 'Set Random' button can be used to generate a random stimulation setting
![Slide3](https://user-images.githubusercontent.com/66339367/111886373-8345db00-89a3-11eb-816c-d084e8e1693f.jpeg)

Once the stimulation settings have been selected, the 'Update Settings' is used to apply them to the unknown objective.
![Slide4](https://user-images.githubusercontent.com/66339367/111886376-8345db00-89a3-11eb-8564-1f310c2e48ce.jpeg)

The stimulation setting is added to the log along with a placeholder for the tremor value.
![Slide5](https://user-images.githubusercontent.com/66339367/111886377-8345db00-89a3-11eb-85c7-341c856356af.jpeg)

The output of the objective is displayed on the tremor gauge. This is intentionally difficult to read to create a natural measurement noise.
![Slide6](https://user-images.githubusercontent.com/66339367/111886378-83de7180-89a3-11eb-9b90-fe097b90d8f0.jpeg)

The reading of the gauge is then entered in the Tremor Measurment field.
![Slide7](https://user-images.githubusercontent.com/66339367/111886379-83de7180-89a3-11eb-9f0e-87d96b33b85e.jpeg)

Once the tremor value is entered, the 'Submit' button is used to update the table and return to selecting stimulation settings.
![Slide8](https://user-images.githubusercontent.com/66339367/111886380-83de7180-89a3-11eb-9264-e2f2049e04de.jpeg)

After an initial set of stimulation settings (burn-in), the optimization algorithm will have enough data to *start* estimating the best stimulation setting. However, this estimate will improve as additional data is collected.
![Slide9](https://user-images.githubusercontent.com/66339367/111886381-84770800-89a3-11eb-85d1-2f55dc179318.jpeg)

To immediately test the estimated optimal stimulation setting, select the 'Set Estimated Best' button.
![Slide10](https://user-images.githubusercontent.com/66339367/111886382-84770800-89a3-11eb-8147-e86d2d86348b.jpeg)

Alternatively, the 'Continue Searching' button allows the software to select the next stimulation setting to explore using the optimization algorithm. At any point, the user can override the suggestions from the algortihm.
![Slide11](https://user-images.githubusercontent.com/66339367/111886383-84770800-89a3-11eb-9c89-b414bad6e2a4.jpeg)

The settings are then updated,
![Slide12](https://user-images.githubusercontent.com/66339367/111886384-84770800-89a3-11eb-8676-48fb8464a390.jpeg)

and the process is repeated,
![Slide13](https://user-images.githubusercontent.com/66339367/111886385-850f9e80-89a3-11eb-92bc-582fda44b468.jpeg)

until converging on a solution with an estimated low tremor.
![Slide14](https://user-images.githubusercontent.com/66339367/111886386-850f9e80-89a3-11eb-995f-40986fc6a77c.jpeg)

The *actual* optimum of the objective function can be seen by seleting the button in the bottom left.
![Slide15](https://user-images.githubusercontent.com/66339367/111886387-850f9e80-89a3-11eb-94fe-d87b6ebbf320.jpeg)

