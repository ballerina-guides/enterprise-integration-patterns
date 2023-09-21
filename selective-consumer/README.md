How to test run the sample
----------------------------

1. Start the mock graphql service `inventoryService.bal` from inside the `tests` folder.
    ```
    bal run inventoryService.bal
    ```

2. Comment the graphql client pointing to `blackwellsbooks.myshopify.com.balmock.io` and uncomment the graphql client pointing to `localhost:8080` in `selective-consumer.bal` file.

3. Inside the `selective-consumer` folder, run the sample.
    ```
    bal run selective-consumer.bal -- electronics
    ```
